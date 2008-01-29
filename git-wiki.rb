%w(rubygems sinatra grit maruku rubypants).each { |l| require l }

GIT_REPO = '/home/simon/wiki'
GIT_DIR  = File.join(GIT_REPO, '.git')
HOMEPAGE = 'HelloWorld'

unless File.exists?(GIT_DIR) && File.directory?(GIT_DIR)
  FileUtils.mkdir_p(GIT_DIR)
  puts "Initializing repository in #{GIT_REPO}..."
  `git --git-dir #{GIT_DIR} init`
end

class Page
  attr_reader :name

  def initialize(name)
    @name = name
    @filename = File.join(GIT_REPO, @name)
    @repo = Grit::Repo.new(GIT_REPO)
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
    return false if @repo.commits.empty?
    @repo.commits.first.tree.contents.map { |b| b.name }.include?(@name)    
  end
end

get '/' do
  redirect '/' + HOMEPAGE
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
  %body
    #{content}
  )
end

def show
  layout(@page.name, %q(
    %h1= @page.name
    %p
      %a{:href => '/e/' + @page.name} Edit
    #page_content= @page.body
  ))
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
