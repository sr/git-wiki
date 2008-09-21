#!/usr/bin/env ruby
require 'rubygems'
gem 'mojombo-grit'

%w(rubygems
sinatra
grit
haml
sass
bluecloth).each { |dependency| require dependency }

begin
  require 'thin'
rescue LoadError
  puts '# May I suggest you to use Thin?'
end

class String
  def to_html
    BlueCloth.new(self).to_html
  end

  def linkify
    self.gsub(/([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/) do |page|
      %Q{<a class="#{Page.css_class_for(page)}" href="/#{page}">#{page.titleize}</a>}
    end
  end

  def titleize
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2').gsub(/([a-z\d])([A-Z])/,'\1 \2')
  end

  def without_ext
    self.sub(File.extname(self), '')
  end
end

class PageNotFound < Sinatra::NotFound
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class Page
  class << self
    attr_accessor :repo

    def find_all
      return [] if repo.tree.contents.empty?
      repo.tree.contents.collect { |blob| new(blob) }
    end

    def find(name)
      page_blob = find_blob(name)
      raise PageNotFound.new(name) unless page_blob
      new(page_blob)
    end

    def find_or_create(name)
      find(name)
    rescue PageNotFound
      new(create_blob_for(name))
    end

    def css_class_for(name)
      find(name)
      'exists'
    rescue PageNotFound
      'unknown'
    end

    private
      def find_blob(page_name)
        repo.tree/(page_name + PageExtension)
      end

      def create_blob_for(page_name)
        Grit::Blob.create(repo, :name => page_name + PageExtension, :data => '')
      end
  end

  def initialize(blob)
    @blob = blob
  end

  def to_html
    content.linkify.to_html
  end

  def to_s
    name
  end

  def new?
    @blob.id.nil?
  end

  def name
    @blob.name.without_ext
  end

  def content
    @blob.data
  end

  def update_content(new_content)
    return if new_content == content
    File.open(file_name, 'w') { |f| f << new_content }
    add_to_index_and_commit!
  end

  private
    def add_to_index_and_commit!
      Dir.chdir(GitRepository) { Page.repo.add(@blob.name) }
      Page.repo.commit_index(commit_message)
    end

    def file_name
      File.join(GitRepository, name + PageExtension)
    end

    def commit_message
      new? ? "Created #{name}" : "Updated #{name}"
    end
end

use_in_file_templates!

configure do
  GitRepository = ENV['GIT_WIKI_REPO'] || File.join(ENV['HOME'], 'wiki')
  PageExtension = '.markdown'
  Homepage = 'Home'
  set_option :haml,  :format        => :html4,
                     :attr_wrapper  => '"'

  begin
    Page.repo = Grit::Repo.new(GitRepository)
  rescue Grit::InvalidGitRepositoryError, Grit::NoSuchPathError
    abort "#{GitRepository}: Not a git repository. Install your wiki with `rake bootstrap`"
  end
end

error PageNotFound do
  page = request.env['sinatra.error'].name
  redirect "/e/#{page}"
end

helpers do
  def title(title=nil)
    @title = title.to_s unless title.nil?
    @title
  end

  def list_item(page)
    '<a class="page_name" href="/%s">%s</a>' % [page, page.name.titleize]
  end
end

before do
  content_type 'text/html', :charset => 'utf-8'
end

get '/' do
  redirect '/' + Homepage
end

get '/_stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/_list' do
  @pages = Page.find_all
  haml :list
end

get '/:page' do
  @page = Page.find(params[:page])
  haml :show
end

get '/e/:page' do
  @page = Page.find_or_create(params[:page])
  haml :edit
end

post '/e/:page' do
  @page = Page.find_or_create(params[:page])
  @page.update_content(params[:body])
  redirect "/#{@page}"
end

__END__
@@ layout
!!! strict
%html
  %head
    %title= title
    %link{:rel => 'stylesheet', :href => '/_stylesheet.css', :type => 'text/css'}
    - Dir[Sinatra.application.options.public + '/*.js'].reverse.each do |lib|
      %script{:src => "/#{File.basename(lib)}", :type => 'text/javascript'}
    :javascript
      $(document).ready(function() {
        $.hotkeys.add('Ctrl+h', function() { document.location = '/#{Homepage}' })
        $.hotkeys.add('Ctrl+l', function() { document.location = '/_list' })

        /* title-case-ification */
        document.title = document.title.toTitleCase();
        $('h1:first').text($('h1:first').text().toTitleCase());
        $('a').each(function(i) {
          var e = $(this)
          e.text(e.text().toTitleCase());
        })
      })
  %body
    #content= yield

@@ show
- title @page.name.titleize
:javascript
  $(document).ready(function() {
    $.hotkeys.add('Ctrl+e', function() { document.location = '/e/#{@page}' })
  })
%h1= title
#page_content
  ~"#{@page.to_html}"

@@ edit
- title "Editing #{@page.name.titleize}"
%h1= title
%form{:method => 'POST', :action => "/e/#{@page}"}
  %p
    %textarea{:name => 'body', :rows => 20, :cols => 80}= @page.content
  %p
    %input.submit{:type => :submit, :value => 'Save as the newest version'}
    or
    %a.cancel{:href=>"/#{@page}"} cancel

@@ list
- title "Listing pages"
%h1 All pages
- if @pages.empty?
  %p No pages found.
- else
  %ul#pages_list
    - @pages.each_with_index do |page, index|
      - if (index % 2) == 0
        %li.odd=  list_item(page)
      - else
        %li.even= list_item(page)

@@ stylesheet
body
  :font
    family: "Lucida Grande", Verdana, Arial, Bitstream Vera Sans, Helvetica, sans-serif
    size: 14px
    color: black
  line-height: 160%
  background-color: white
  margin: 0
  padding: 0
#content
  padding: 2em
a
  padding: 2px
  color: blue
  &.exists
    &:hover
      background-color: blue
      text-decoration: none
      color: white
  &.unknown
    color: gray
    &:hover
      background-color: gray
      color: white
      text-decoration: none
  &.cancel
    color: red
    &:hover
      text-decoration: none
      background-color: red
      color: white
textarea
  font-family: courrier
  font-size: 14px
  line-height: 18px
  padding: 5px
button.submit
  font-weight: bold
ul#pages_list
  list-style-type: none
  margin: 0
  padding: 0
  li
    padding: 5px
    &.odd
      background-color: #D3D3D3
