require "rubygems"
require "sinatra/base"
require "haml"
require "grit"
require "rdiscount"

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
    attr_accessor :orig_string, :start, :attributes_str, :attributes, :desc

    TAGGED_VALUE_REGEX = /(\w+)\:(\w+)\s+/

    def self.parse(from_string)
      t = Task.new
      t.orig_string = from_string
      return nil unless t.orig_string =~
        /^((?: DO|TODO|DONE|INCLUDE):?\s+)    # 1:TODO with optional colon
        (#{TAGGED_VALUE_REGEX}+)?  # tagged values 2:, 3:, 4:
        (.*)                         # 5:title
        /x
      t.start = $1
      t.attributes_str = $2
      t.desc = $+

      t.attributes = []
      t.attributes = $2.scan(TAGGED_VALUE_REGEX) if $2

      require 'pp'
      pp t
      t
    end

    def to_html
      html = "<span style='font-weight:bold'>#{start}</span>#{attributes_str}#{desc}"
      html = "<del>#{html}</del>" if done?
      "<div class='todo'>#{html}</div>"
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

  class TaskList
    attr_accessor :example, :tasks

    def self.from_example(example)
      res = TaskList.new
      res.example = example
      if example.project
        begin
          res.fill_from_git(example.project)
        rescue PageNotFound => p
          puts "NOT FOUDN"
          res.example.desc = "Page not found #{p.name}"
        end
      end
      res
    end

    def initialize
      tasks = []
    end

    def fill_from_git(page)
      puts "in fill_rom_git"
      puts page.inspect
      p = Page.find(page)
      if p
        p.content.each_line do |line|
          task = Task.parse(line) # try every line as a task decription
          tasks << task unless task.nil?
        end
      end
    end

    def fill_from_url()
    end

    def filter(example)
    end

    def to_html
      example.to_html + "\n Details will appear here"
    end
  end

  class Page
    def self.find_all
      return [] if repository.tree.contents.empty?
      repository.tree.contents.collect { |blob| new(blob) }.sort_by {|page| page.name.downcase}
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
      html = RDiscount.new(wiki_link(inject_todo(content))).to_html
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
          list = TaskList.from_example(task)
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
        str.gsub(/([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/) { |page|
          %Q{<a class="#{self.class.css_class_for(page)}"} +
            %Q{href="/#{page}">#{page}</a>}
        }
      end
  end

  class App < Sinatra::Base
    set :app_file, __FILE__
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }
    use_in_file_templates!

    error PageNotFound do
      page = request.env["sinatra.error"].name
      redirect "/#{page}/edit"
    end

    before do
      content_type "text/html", :charset => "utf-8"
    end

    get "/" do
      redirect "/" + GitWiki.homepage
    end

    get "/pages" do
      @pages = Page.find_all
      haml :list
    end

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
      haml :edit
    end

    get "/:page" do
      @page = Page.find(params[:page])
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
        @title = title.to_s unless title.nil?
        @title
      end

      def list_item(page)
        %Q{<a class="page_name" href="/#{page}">#{page.name}</a>}
      end
  end
end

__END__
@@ layout
!!!
%html
  %head
    %title= title
    %style
      :sass
        body
          margin-left: 2em
          font-family: monospace
        h1, h2, h3, h4, h5, h6
          font-size: 100%
        h1
          text-decoration: underline
          letter-spacing: 0.3em
        h2
          text-decoration: underline
        del
          color: gray
        div.todo
          line-height: 160%
        ul
          padding-left: 0.3em
          list-style-type: square
          list-style-position: inside
        li ul
          list-style-type: circle
          padding-left: 1.2em
        li ul li ul
          list-style-type: disc
        ul#navigation
          list-style-type: none
          display: inline
          margin: 0
          padding: 0
          li
            display: inline
            margin: 0
            padding: 0
            padding-right: 1em
        a.service
          color: #4377EF
          text-decoration: none
          font-weight: bold
        a.service:hover
          border-bottom: 2px dotted #4377EF
        @media print
          .service
            display: none
        body.compact
          margin-left: inherit
          font-family: Helvetica, sans-serif
          .service
            display: none
  %body{:class => @global_style}
    %ul#navigation
      %li
        %a.service{ :href => "/#{GitWiki.homepage}" } Home
      %li
        %a.service{ :href => "/pages" } All pages
    #content= yield

@@ show
- title @page.name
#content
  ~"#{@page.to_html}"
#edit
  %a.service{:href => "/#{@page}/edit"} Edit this page

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
