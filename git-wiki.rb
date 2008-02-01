%w(rubygems sinatra grit maruku rubypants).each { |l| require l }

GIT_REPO = ENV['HOME'] + '/wiki'
GIT_DIR  = File.join(GIT_REPO, '.git')
HOMEPAGE = 'HelloWorld'

unless File.exists?(GIT_DIR) && File.directory?(GIT_DIR)
  FileUtils.mkdir_p(GIT_DIR)
  puts "Initializing repository in #{GIT_REPO}..."
  `git --git-dir #{GIT_DIR} init`
end

$repo = Grit::Repo.new(GIT_REPO)

class Page
  attr_reader :name

  def initialize(name)
    @name = name
    @filename = File.join(GIT_REPO, @name)
  end

  def body
    @body ||= Maruku.new(RubyPants.new(raw_body).to_html).to_html
  end

  def raw_body
    @raw_body ||= File.exists?(@filename) ? File.read(@filename) : ''
  end

  def body=(content)
    File.open(@filename, 'w') { |f| f << content }
    message = tracked? ? "Edited #{@name}" : "Created #{@name}"
    `cd #{GIT_REPO} && git add #{@name} && git commit -m #{message}`
  end

  def tracked?
    return false if $repo.commits.empty?
    $repo.commits.first.tree.contents.map { |b| b.name }.include?(@name)    
  end

  def to_s
    "<li><a href='/#{@name}'>#{@name}</a> (<a href='/e/#{@name}'>edit</a>)</li>"
  end
end

get '/' do
  redirect '/' + HOMEPAGE
end

get '/_list' do
  @pages = $repo.commits.first.tree.contents.map { |blob| Page.new(blob.name) }
  puts @pages.inspect
  haml(list)
end

get '/_stylesheet.css' do
  css = Sass::Engine.new(stylesheet())
  css.render
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
    %link{:rel => 'stylesheet', :href => '_stylesheet.css', :type => 'text/css', :media => 'screen'}
  %body
    #navigation
      %a{:href => '/'} Home
      %a{:href => '/_list'} List
    #{content}
  )
end

def show
  layout(@page.name, %q(
    %h1
      = @page.name
      %span.edit_link
        %a{:href => '/e/' + @page.name} edit
    #page_content= @page.body
  ))
end

def stylesheet
"
body
  :font
    family: Helvetica, sans-serif
    size: 13px

#navigation
  a
    background-color: #e0e0e0
    padding: 2px
    color: black
  a:hover
    text-decoration: none

h1
  display: block
  border-bottom: 1px solid black

.edit_link
  a
    color: black
    font-size: 12px
    font-weight: normal
  )
"
end

def edit
  layout("Editing #{@page.name}", %q(
    %h1
      Editing
      %a{:href => '/'+@page.name}= @page.name
    %form{ :method => 'POST', :action => '/e/' + params[:page]}
      %p
        ="<textarea name ='body' rows='30' cols='120'>#{@page.raw_body}</textarea>"
      %p
        %input{ :type => :submit, :value => 'save!' }
  ))
end

def list
  layout('Listing pages', %q{
    %h1 All pages
    - if @pages.empty?
      %p No page found :-(
    - else
      %ul= @pages.each(&:to_s)
  })
end
