module GitWiki
  class App < Sinatra::Base
    enable :static
    set :public, Proc.new { File.join(root, "public") }
    set :app_file, __FILE__
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }

    error PageNotFound do
      page = request.env["sinatra.error"].name
      redirect "/#{page}?edit=1"
    end

    before do
      content_type "text/html", :charset => "utf-8"
      @page_class = [];
    end

    get "/stylesheets/application.css" do
      content_type "text/css; charset=utf-8", :charset => "utf-8"
      sass :"application"
    end

    post "/preview" do
      RDiscount.new(params[:body]).to_html
    end

    get "/" do
      redirect "/" + GitWiki.homepage
    end

    get "/pages" do
      @pages = Page.find_all
      haml :list
    end

    get "/*" do
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

  end
end