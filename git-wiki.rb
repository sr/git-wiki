#!/usr/bin/env ruby

%w(rubygems sinatra git bluecloth rubypants haml).each do |dependency| 
  begin
    require dependency
  rescue LoadError => e
    puts "You need to install #{dependency} before we can proceed"
  end
end

GIT_REPO = ENV['HOME'] + '/wiki'
HOMEPAGE = 'Home'

unless File.exists?(GIT_REPO) && File.directory?(GIT_REPO)
  puts "Initializing repository in #{GIT_REPO}..."
  Git.init(GIT_REPO)
end

class Page
  class << self
    attr_accessor :repo
  end

  self.repo = Git.open(GIT_REPO)

  def self.find_all
    return [] if Page.repo.log.size == 0
    Page.repo.log.first.gtree.children.map { |name, blob| Page.new(name) }.sort_by { |p| p.name }
  end

  attr_reader :name

  def initialize(name)
    @name = name
    @filename = File.join(GIT_REPO, @name)
  end

  def body
    @body ||= BlueCloth.new(RubyPants.new(raw_body).to_html).to_html.
      gsub(/\b((?:[A-Z]\w+){2,})/) do |page|
        css_class = Page.new(page).tracked? ? 'exists' : 'unknown'
        "<a class='#{css_class}' href='#{page}'>#{page}</a>"
      end
  end

  def raw_body
    @raw_body ||= File.exists?(@filename) ? File.read(@filename) : ''
  end

  def body=(content)
    File.open(@filename, 'w') { |f| f << content }
    message = tracked? ? "Edited #{@name}" : "Created #{@name}"
    Page.repo.add(@name)
    Page.repo.commit(message)
  end

  def tracked?
    Page.repo.ls_files.keys.include?(@name)
  end

  def to_s
    "<li><strong><a href='/#{@name}'>#{@name}</a></strong> — <a href='/e/#{@name}'>edit</a></li>"
  end
end

get('/') { redirect '/' + HOMEPAGE }
get('/_stylesheet.css') { Sass::Engine.new(File.read(__FILE__).gsub(/.*__END__/m, '')).render }

get '/_list' do
  @pages = Page.find_all
  haml(list)
end

get '/:page' do
  @page = Page.new(params[:page])
  @page.tracked? ? haml(show) : redirect('/e/' + @page.name)
end

get '/e/:page' do
  @page = Page.new(params[:page])
  haml(edit)
end

post '/e/:page' do
  @page = Page.new(params[:page])
  @page.body = params[:body]
  redirect '/' + @page.name
end

def layout(title, content)
  %Q(
%html
  %head
    %title #{title}
    %link{:rel => 'stylesheet', :href => '/_stylesheet.css', :type => 'text/css', :media => 'screen'}
    %meta{'http-equiv' => 'Content-Type', :content => 'text/html; charset=utf-8'}

  %body
    #navigation
      %a{:href => '/'} Home
      %a{:href => '/_list'} List
    #{content}
  )
end

def show
  layout(@page.name, %q(
      %a{:href => '/e/' + @page.name, :class => 'edit_link'} edit this page
    %h1{:class => 'page_title'}= @page.name
    #page_content= @page.body
  ))
end

def edit
  layout("Editing #{@page.name}", %q(
    %h1
      Editing
      = @page.name
      %a{:href => 'javascript:history.back()', :class => 'cancel'} Cancel
    %form{ :method => 'POST', :action => '/e/' + params[:page]}
      %p
        ~"<textarea name='body' rows='25' cols='130'>#{@page.raw_body}</textarea>"
      %p
        %input{:type => :submit, :value => 'Save as the newest version', :class => :submit}
  ))
end

def list
  layout('Listing pages', %q{
    %h1 All pages
    - if @pages.empty?
      %p No pages found.
    - else
      %ul= @pages.each(&:to_s)
  })
end

__END__
body
  :font
    family: Verdana, Arial, "Bitstream Vera Sans", Helvetica, sans-serif
    size: 14px
    color: black
  line-height: 160%
  background-color: white
  margin: 2em

#navigation
  a
    background-color: #e0e0e0
    color: black
    text-decoration: none
    padding: 2px
  padding: 5px
  border-bottom: 1px black solid

h1
  display: block
  padding-bottom: 5px

a
  color: black

a.exists
  font-weight: bold
a.unknown
  font-style: italic

.submit
  font-size: large
  font-weight: bold

.page_title
  font-size: xx-large

.edit_link
  color: black
  font-size: 14px
  font-weight: bold
  background-color: #e0e0e0
  font-variant: small-caps
  text-decoration: none

.cancel
  background-color: #e0e0e0
  font-weight: normal
  text-decoration: none
  font-size: 14px 

.cancel:before
  content: "("

.cancel:after
  content: ")"
