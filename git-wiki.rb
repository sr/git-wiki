require "sinatra/base"
require "haml"
require "sass"
require "grit"
require "rdiscount"
require "rack-xslview"
require "rack-docunext-content-length"

require "git_wiki/page_not_found"
require "git_wiki/page"

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



  class App < Sinatra::Base
    set :public, File.dirname(__FILE__) + '/public'
    set :static, true
    set :app_file, __FILE__
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }
    enable :inline_templates

    error PageNotFound do
      page = request.env["sinatra.error"].name
      redirect "/#{page}?edit=1"
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
    end


    #get "/:page/history" do
    #  @page = Page.history
    #  haml :history
    #end

    get "/*" do
      ObjectSpace.each_object(Sinatra::Base){|o| puts o}
      path = params[:splat].join('/')
      if not params[:edit].nil?
        @page = Page.find_or_create(path)
        haml :edit
      else
        @page = Page.find(path)
        haml :show
      end
    end

    post "/*" do
      path = params[:splat].join('/')
      @page = Page.find_or_create(path)
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
