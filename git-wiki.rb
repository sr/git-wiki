#!/usr/bin/env ruby
%w(sinatra haml sass rubygems git bluecloth rubypants).each do |dependency|
  begin
    $: << File.expand_path(File.dirname(__FILE__) + "/vendor/#{dependency}/lib")
    require dependency
  rescue LoadError
    abort "Unable to load #{dependency}. Did you run 'git submodule init' ? If so install #{dependency}"
  end
end

GIT_REPO = ENV['HOME'] + '/wiki' unless defined?(GIT_REPO)
HOMEPAGE = 'Home' unless defined?(HOMEPAGE)

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
        "<a class='#{Page.new(page).tracked? ? 'exists' : 'unknown'}' href='#{page}'>#{page}</a>"
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
    "<a class='page_name' href='/#{@name}'>#{@name}</a>&nbsp;<a class='edit' href='/e/#{@name}'>edit</a></li>"
  end
end

use_in_file_templates!

helpers do
  def title(title=nil)
    @title = title unless title.nil?
    @title
  end
end

before do
  header 'Content-Type' => 'text/html; charset=utf-8'
end

get('/') { redirect '/' + HOMEPAGE }

get('/_stylesheet.css') do
  header 'Content-Type' => 'text/css; charset=utf-8'
  Sass::Engine.new(template('stylesheet')).render
end

get '/_list' do
  @pages = Page.find_all
  haml :list
end

get '/:page' do
  @page = Page.new(params[:page])
  @page.tracked? ? haml(:show) : redirect("/e/#{@page.name}")
end

# Waiting for Black's new awesome route system
get '/:page.txt' do
  @page = Page.new(params[:page])
  throw :halt, [404, "Unknown page #{format[:page]}"] unless @page.tracked?
  header 'Content-Type' => 'text/plain; charset=utf-8'
  @page.raw_body
end

get '/e/:page' do
  @page = Page.new(params[:page])
  haml :edit
end

post '/e/:page' do
  @page = Page.new(params[:page])
  @page.body = params[:body]
  request.xhr? ? @page.body : redirect('/' + @page.name)
end

__END__
## layout
%html
  %head
    %title= title
    %link{:rel => 'stylesheet', :href => '/_stylesheet.css', :type => 'text/css'}
    %script{:src => '/jquery-1.2.3.min.js', :type => 'text/javascript'}
    %script{:src => '/jquery.jeditable.js', :type => 'text/javascript'}
    %script{:src => '/jquery.autogrow.js', :type => 'text/javascript'}
    %script{:src => '/jquery.hotkeys.js', :type => 'text/javascript'}
    :javascript
      $(document).ready(function() {
        $('#navigation').hide();
        $('#edit_link').hide();
        $.hotkeys.add('Ctrl+h', function() { document.location = '#{HOMEPAGE}' })
        $.hotkeys.add('Ctrl+l', function() { document.location = '/_list' })
      })
  %body
    %ul#navigation
      %li
        %a{:href => '/'} Home
      %li
        %a{:href => '/_list'} List
    #content= yield

## show
- title @page.name
:javascript
  $(document).ready(function() {
    $.editable.addInputType('autogrow', {
      element : function(settings, original) {
        var textarea = $('<textarea>');
        if (settings.rows) {
          textarea.attr('rows', settings.rows);
        } else {
          textarea.height(settings.height);
        }
        if (settings.cols) {
          textarea.attr('cols', settings.cols);
        } else {
          textarea.width(settings.width);
        }
        $(this).append(textarea);
        return(textarea);
      },
      plugin : function(settings, original) {
        $('textarea', this).autogrow(settings.autogrow);
      }
    });

    $('#page_content').editable('/e/#{@page.name}', {
      loadurl: '/#{@page.name}.txt',
      submit: '<button type="submit" style="font-weight: normal;">Save as the newest version</button>',
      cancel: '<a title="Cancel editing" href="" style="text-decoration: underline; margin-left: 5px; crosshair: pointer;">cancel</a>',
      event: 'dblclick',
      type: 'autogrow',
      name: 'body',
      onblur: 'ignore',
      tooltip: '',
      indicator: 'Saving...',
      loadtext: '',
      cssclass: 'edit_form',
      autogrow: {
        maxHeight: 100,
        lineHeight: 16,
        minHeight: 84
      },
      callback: function(v, s) {
        $('#content').prepend('<p id="notice">New version successfuly saved!</p>');
        $('#notice').fadeOut(100, function() { $(this).remove() })
      }
    })
  })
%a#edit_link{:href => '/e/' + @page.name} edit this page
%h1= title
#page_content= @page.body

## edit
- title "Editing #{@page.name}"

%h1= title
%form{ :method => 'POST', :action => '/e/' + @page.name}
  %p
    ~"<textarea name='body' rows='16' cols='60'>#{@page.raw_body}</textarea>"
  %p
    %input.submit{:type => :submit, :value => 'Save as the newest version'}
    or
    %a.cancel{:href=>'/' + @page.name} cancel

## list
- title "Listing pages"

%h1 All pages
- if @pages.empty?
%p No pages found.
- else
  %ul#pages_list
  - @pages.each_with_index do |page, index|
    - if (index % 2) == 0
      %li.odd= page
    - else
      %li.even= page
  - end

## stylesheet
body
  :font
    family: "Lucida Grande", Verdana, Arial, Bitstream Vera Sans, Helvetica, sans-serif
    size: 14px
    color: black
  line-height: 160%
  background-color: white
  margin: 0
  padding: 0

#navigation
  padding-left: 2em
  margin: 0
  li
    list-style-type: none
    display: inline

#content
  padding: 2em
.notice
  background-color: #ffc
  padding: 6px

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

textarea
  font-family: courrier
  padding: 5px
  font-size: 14px
  line-height: 18px

.edit_link
  display: block
  background-color: #ffc
  font-weight: bold
  text-decoration: none
  color: black
  &:hover
    color: white
    background-color: red

.submit
  font-weight: bold

.cancel
  color: red
  &:hover
    text-decoration: none
    background-color: red
    color: white
ul#pages_list
  list-style-type: none
  margin: 0
  padding: 0
  li
    padding: 5px
    a.edit
      display: none 
    &.odd
      background-color: #D3D3D3
