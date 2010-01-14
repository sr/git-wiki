require "sinatra/base"
require "haml"
require "grit"
require "rdiscount"
require 'rack-xslview'
require 'rexml/document'
require 'rack-docunext-content-length'

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

  class Page
    def self.find_all
      return [] if repository.tree.contents.empty?
      repository.tree.contents.collect { |blob| new(blob) }
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
      RDiscount.new(wiki_link(content)).to_html
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
      content_type "text/html", :charset => "utf-8"
    end

    get "/" do
      redirect "/" + GitWiki.homepage
    end

    get "/pages" do
      @pages = Page.find_all
      haml :list
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
    %style{ :type=> "text/css" } .unknown { color:red; }
    %script{ :type=> "text/javascript", :src=> "/s/js/jquery/dist/jquery.min.js" }
  %body
    %ul
      %li
        %a{ :href => "/#{GitWiki.homepage}" } Home
      %li
        %a{ :href => "/pages" } All pages
    #content= yield

@@ show
- title @page.name
#edit
  %a{:href => "/#{@page}/edit"} Edit this page
%h1= title
#content
  ~"#{@page.to_html}"

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
