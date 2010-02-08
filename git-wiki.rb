require "rubygems"
require "sinatra/base"
require "haml"
require "sass"
require "grit"
require "rdiscount"
require "rexml/document"
require "rack-xslview"
require "rack-docunext-content-length"

require 'pp' # TODO: remove
require 'ruby-debug' # TODO: remove

module GitWiki
  class << self
    attr_accessor :homepage, :extension, :repository
  end

  def self.new(repository, extension, homepage)
    self.homepage   = homepage
    self.extension  = extension
    self.repository = Grit::Repo.new(repository)

    App
  end

  class PageNotFound < Sinatra::NotFound
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  class Task
    attr_accessor :orig_string, :start, :orig_attributes_str, :attributes, :desc, :origin

    TAGGED_VALUE_REGEX = /(\w+)\:(\w+)\s+/

    def self.parse(from_string)
      t = Task.new
      t.orig_string = from_string + ' ' # add space to parse include statements without description
      return nil unless t.orig_string =~
        /^(?: \s*\*?\s*)                  # allow leading * with white space to both sides
        ((?: DO|TODO|DONE|INCLUDE):?\s+)  # 1:TODO with optional colon
        (#{TAGGED_VALUE_REGEX}+)?         # tagged values 2:, 3:, 4:
        (.*)                              # 5:title
        /x
      t.start = $1
      t.orig_attributes_str = $2
      t.desc = $+.strip

      t.attributes = []
      t.attributes = $2.scan(TAGGED_VALUE_REGEX) if $2

      t
    end

    def inner_html
      attr_str = attributes.map{|key, value| "#{key}:#{value} "}.join
      html = "<span style='font-weight:bold'>#{start}</span>#{attr_str}#{desc}"
      html = "<del>#{html}</del>" if done?
      html
    end

    def wrap_div(inner)
      "<div class='todo'>#{inner}</div>"
    end

    def to_html
      wrap_div(inner_html)
    end

    def done?
      start =~ /DONE/
    end

    def include_statement?
      start =~ /INCLUDE/
    end

    def [](key)
      hit = attributes.detect {|k, value| k.to_s == key.to_s}
      hit ? hit[1] : nil
    end

    def project
      self[:project]
    end

    def context
      self[:context]
    end
  end

  Origin = Struct.new(:name, :view_url, :edit_url, :attributes) # referencing (parent) page

  # List of todo tasks
  class TaskList
    attr_accessor :example, :tasks

    def initialize
      self.tasks = []
    end

    # @example [Task] contains attributes for task filtering ("filter by example"),
    #                 also defines the source of the tasks (Wiki-Name or url)
    # @recursive_origins [string Array] nil for no recursion or an array of already
    #                              visited nodes; needed to avoid endless recursion
    def self.from_example(example, recursive_origins = nil)
      res = TaskList.new
      res.example = example
      merge_attributes = {}
      merge_attributes[:project] = example.project if example.project
      merge_attributes[:context] = example.context if example.context

      if example[:wiki] == 'all' # load all tasks from all wiki pages
        Page.find_all.each {|p| puts "loading #{p.name}"; res.fill_from_git p.name, merge_attributes, recursive_origins}
      elsif example.desc =~ /^http/ # load by url
        res.fill_from_url(example.desc, merge_attributes) rescue res.example.desc "CAN NOT RETRIEVE URL"
      else # load from one wiki page
        wiki_name = "Project#{example.project}" if example.project
        wiki_name = "Context#{example.context}" if example.context
        wiki_name = example[:wiki] if example[:wiki]
        if wiki_name
          begin
            res.fill_from_git wiki_name, merge_attributes, recursive_origins
          rescue PageNotFound => p
            res.example.desc = "PAGE NOT FOUND #{p.name}"
          end
        end
      end
      res
    end

    def self.derive_attributes_from_page_name(name)
      res = {}
      res[:project] = $1 if name =~ /Project(\w+)/
      res[:context] = $1 if name =~ /Context(\w+)/
      res
    end

    def fill_from_git(page, merge_attributes = {}, recursive_origins = nil)
      if p = Page.find(page)
        attrs = TaskList.derive_attributes_from_page_name(p.name)
        o = Origin.new(page, "/#{page}", "/#{page}/edit", attrs.merge(merge_attributes))
        fill_from_string(p.content, attrs, o, recursive_origins)
      end
    end

    def fill_from_url(url, merge_attributes = {})
      require 'rest_client'
      content = RestClient.get(url) rescue 'Content could not be retrieved.'
      o = Origin.new(url, url, nil)
      fill_from_string(content, merge_attributes, o)
    end

    def fill_from_string(content, merge_attributes, origin, recursive_origins = nil)
      # avoid endless recursion
      if recursive_origins && recursive_origins.detect?{|o| o.name == origin.name}
        puts "Breaking endless recursion #{recursive_origins.inspect}"
        return
      end
      recursive_origins << origin if recursive_origins

      content.each_line do |line|
        task = Task.parse(line) # try every line as a task decription
        if !task.nil?
          puts "merge_attr #{merge_attributes.inspect}"
          merge_attributes.each do |key, value|
            task.attributes << [key, value] unless task[key]
          end
          task.origin = origin.edit_url || origin.view_url
          if task.include_statement? && recursive_origins
            list = TaskList.from_example(task, recursive_origins)
            self.tasks = self.tasks + list.tasks
          else
            tasks << task
          end
        end
      end
    end

    def filter(example)
    end

    def to_html
      tasks_html = tasks.map do |task|
        link = " (<a href='#{task.origin}'>edit</a>)"
        task.wrap_div(task.inner_html + link)
      end
      "<div class='included'>
         <h2>#{example.to_html} (#{tasks.size} tasks)</h2>
         #{tasks_html.join("\n")}
       </div>"
    end
  end

  class Page
    def self.find_all
      return [] if repository.tree.contents.empty?
      repository.tree.contents.
        select {|blob| File.extname(blob.name) == GitWiki.extension }.
        collect {|blob| new(blob)}.
        sort_by {|page| page.name.downcase}
    end

    def self.find(name)
      page_blob = find_blob(name)
      raise PageNotFound.new(name) unless page_blob
      new(page_blob)
    end

    def self.find_or_create(name)
      find(name)
    rescue PageNotFound
      new(create_blob_for(name))
    end

    def self.css_class_for(name)
      find(name)
      "exists"
    rescue PageNotFound
      "unknown"
    end

    def self.history
      repository.commits
    end

    def self.repository
      GitWiki.repository || raise
    end

    def self.extension
      GitWiki.extension || raise
    end

    def self.find_blob(page_name)
      repository.tree/(page_name + extension)
    end
    private_class_method :find_blob

    def self.create_blob_for(page_name)
      Grit::Blob.create(repository, {
        :name => page_name + extension,
        :data => ""
      })
    end
    private_class_method :create_blob_for

    def initialize(blob)
      @blob = blob
    end

    def to_html
      html = RDiscount.new(inject_todo(content)).to_html
      html = inject_links(inject_header(html))
      html
    end

    def inject_header(orig)
      orig =~ /<h1>/ ? orig : "<h1>#{name}</h1>" + orig
    end

    def inject_todo(orig)
      res = []
      orig.each_line do |line|
        task = Task.parse(line) # try every line as a task decription
        if task.nil?
          res << line
        elsif task.include_statement?
          recursive = task[:recursive] == 'true' ? ["/#{name}"] : nil
          list = TaskList.from_example(task, recursive)
          res << list.to_html
        else
          res << task.to_html
        end
      end
      res.join
    end

    def inject_links(orig)
      orig # disable wiki words
    end

    def to_s
      name
    end

    def new?
      @blob.id.nil?
    end

    def name
      @blob.name.gsub(/#{File.extname(@blob.name)}$/, '')
    end

    def content
      @blob.data
    end

    def update_content(new_content)
      return if new_content == content
      File.open(file_name, "w") { |f| f << new_content }
      add_to_index_and_commit!
    end

    private
      def add_to_index_and_commit!
        Dir.chdir(self.class.repository.working_dir) {
          self.class.repository.add(@blob.name)
        }
        self.class.repository.commit_index(commit_message)
      end

      def file_name
        File.join(self.class.repository.working_dir, name + self.class.extension)
      end

      def commit_message
        new? ? "Created #{name}" : "Updated #{name}"
      end

      def wiki_link(str)
        str.gsub(/\[\[([^\]]+\]\])/) { |page|
            file = page.downcase.gsub('[','').gsub(']','').gsub(/[^a-z0-9]/,'_');
            linktext = page.gsub('[','').gsub(']','');
            %Q{<a class="#{self.class.css_class_for(file)}" } +
            %Q{href="/#{file}">#{linktext}</a>}
        }
      end
  end

  class App < Sinatra::Base
    set :public, File.dirname(__FILE__) + '/public'
    set :static, true
    set :app_file, __FILE__
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }
    use_in_file_templates!

    error PageNotFound do
      page = request.env["sinatra.error"].name
      redirect "/#{page}/edit"
    end

    before do
    end

    get "/styles.css" do
      content_type "text/css", :charset => "utf-8"
      sass :styles
    end

    get "/" do
      redirect "/" + GitWiki.homepage
    end

    get "/pages" do
      @pages = Page.find_all
      haml :list
    end

    get "/commits" do
      @commits = Page.history
      haml :commits
    get "/img/*" do
      git_obj = GitWiki.repository.tree/'img'
      params[:splat].each do |part|
        git_obj = git_obj/part
        not_found if git_obj.nil?
      end
      content_type File.extname(params[:splat].last)
      body git_obj.data
    end

    get "/:page/edit" do
      @page = Page.find_or_create(params[:page])
      @global_style = 'vimlike'
      haml :edit
    end

    #get "/:page/history" do
    #  @page = Page.history
    #  haml :history
    #end

    get "/:page" do
      @page = Page.find(params[:page])
      @global_style = 'vimlike'
      haml :show
    end

    post "/:page" do
      @page = Page.find_or_create(params[:page])
      @page.update_content(params[:body])
      redirect "/#{@page}"
    end

    get "/compact/:page" do # especially suitable for iPhone
      @page = Page.find(params[:page])
      @global_style = 'compact'
      haml :show
    end

    get "/raw/:page" do
      @page = Page.find(params[:page])
      content_type 'text'
      @page.content
    end

    private
      def title(title=nil)
        @title = title.to_s.gsub('_',' ').gsub(/\b\w+/){$&.capitalize} unless title.nil?
        @title
      end

      def list_item(page)
        title = page.name.gsub('_',' ').gsub(/\b\w+/){$&.capitalize}
        %Q{<a class="page_name" href="/#{page}">#{title}</a>}
      end
  end
end

__END__
@@ layout
!!!
%html
  %head
    %title= title
    %script{ :type=> "text/javascript", :src=> "/s/js/jquery/jquery-1.3.2.min.js" }
    %link{ :rel=> "stylesheet", :type=> "text/css", :href=> "/s/css/yui.reset.css" }
    %link{ :href=> "/styles.css", :media=> 'all', :type=> "text/css", :rel=> "stylesheet" }
  %body
    %ul{:id=> 'header-menu'}
=======
    %style
      :sass
        del
          color: gray
        ul.navigation
          list-style-type: none
          display: inline
          margin: 0
          padding: 0
          li
            display: inline
            margin: 0
            padding: 0
            padding-right: 1.5em
        a.service
          color: #4377EF
          text-decoration: none
          font-weight: bold
        a.service:hover
          border-bottom: 2px dotted #4377EF
        div#page_navigation
          margin-top: 0.6em
        div.included
          background-color: #eee
          min-height: 3em
          padding: 0
          margin-top: 0.7em
          h2
            padding: 0
            margin: 0
            position: absolute
            right: 1em
            width: auto
            font-weight: normal !important
            text-decoration: none !important
            color: grey
            text-align: right

        body.vimlike
          margin-left: 2em
          font-family: monospace
          div#content
            h1, h2, h3, h4, h5, h6
              font-size: 100%
            h1
              text-decoration: underline
              letter-spacing: 0.3em
            h2
              text-decoration: underline
            ul
              padding-left: 0.3em
              list-style-type: square
              list-style-position: inside
            li ul
              list-style-type: circle
              padding-left: 1.2em
            li ul li ul
              list-style-type: disc

        @media print
          .service
            display: none
          div.todo
            line-height: 160%

        body.compact
          margin-left: inherit
          font-family: Helvetica, sans-serif
          .service
            display: none
  %body{:class => @global_style}
    %ul.navigation
      %li
        %a.service{ :href => "/#{GitWiki.homepage}" } Home
      %li
        %a{ :href => "/pages" } All pages
      %li
        %a{ :href => "/commits" } Commits
    #container= yield

@@ show
- title @page.name
#page-controls
  %ul
    %li
      %a{:href => "/#{@page}/edit"} Edit this page
    %li
      %a{:href => "/#{@page}/history"} History
%h1= title
        %a.service{ :href => "/pages" } All pages
    = yield

@@ show
- title @page.name
>>>>>>> upstream/master
#content
  ~"#{@page.to_html}"
#page_navigation
  %ul.navigation#edit
    %li
      %a.service{:href => "/#{@page}/edit"} Edit this page
    %li
      %a.service{:href => "/compact/#{@page}"} Compact view
    %li
      %a.service{:href => "/raw/#{@page}"} Raw view

@@ edit
- title "Editing #{@page.name}"
%h1= title
%form{:method => 'POST', :action => "/#{@page}"}
  %p
    %textarea{:name => 'body', :rows => 30, :style => "width: 100%"}= @page.content
  %p
    %input.submit{:type => :submit, :value => "Save as the newest version"}
    or
    %a.cancel{:href=>"/#{@page}"} cancel

@@ list
- title "Listing pages"
%h1 All pages
- if @pages.empty?
  %p No pages found.
- else
  %ul#list
    - @pages.each do |page|
      %li= list_item(page)

@@ commits
- title "Listing commits"
%h1 All commits
- if @commits.empty?
  %p No commits found.
- else
  %ul#list
    - @commits.each do |commit|
      %li= commit.id << " " << commit.authored_date.to_s
