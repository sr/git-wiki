require "sinatra/base"
require "haml"
require "sass"
require "grit"
require "rdiscount"
require 'net/ssh'

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
    set :user, 'albertlash'
    set :host, '192.168.8.2'
    set :haml, { :format        => :html5,
                 :attr_wrapper  => '"'     }

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
      @exclude = ['.gitignore','conf/cyberpulpit','conf/greencomputing','conf/hungryblogger','conf/informedblogging','conf/informedrealestate','conf/mmwiki','conf/neocarz','conf/neofilmz','conf/nexista','conf/nodows','conf/pbooks','conf/sbinfo','conf/telecomrebirth']
      @exclude << 'templates/page'
      @exclude << 'templates/footer'
      @pages = Page.find_all
      @pages.delete_if {|page| @exclude.include?(page.name) }
      haml :list
    end

    get "/commits" do
      @commits = Page.history
      haml :commits
    end
    get "/commit-:wiki" do
      host = settings.host
      stdout = '' << host << "\n"
      Net::SSH.start(host, settings.user) do |ssh|
        ssh.exec!("cd /var/www/svxwikis && git pull && ikiwiki --setup /var/www/svxwikis/conf/#{params[:wiki]}.setup --rebuild") do |channel, stream, data|
          stdout << data if stream == :stdout
        end
      end
      @publish = '<pre>'+stdout+'</pre>'
      haml :publish
    end


    #get "/:page/history" do
    #  @page = Page.history
    #  haml :history
    #end

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


    private
      def title(title=nil)
        @title = title.to_s.gsub('_',' ').gsub(/\b\w+/){$&.capitalize} unless title.nil?
        @title
      end
      def breadcrumbs(title=nil)
        #@title = title.to_s.gsub('_',' ').gsub(/\b\w+/){$&.capitalize} unless title.nil?
        unless title.nil?
          @bc = title.to_s
          if @bc.include?('/')
            @breadc = ''
            @bc = @bc.split('/').map! do |path|
              folder_name = path.gsub('_',' ').gsub(/\b\w+/){$&.capitalize}
              if @breadc.empty?
                path = path + '/index'
              else
                @breadc.gsub!('/index','')
              end
              @breadc << '/' << path
              %Q{<a class="page_name" href="#{@breadc}">#{folder_name}</a>}
            end.join('/')
          end
        end
        @bc
      end

      def list_item(page)
        title = page.name.gsub('_',' ').gsub(/\b\w+/){$&.capitalize}
        %Q{<a class="page_name" href="/#{page}">#{title}</a>}
      end
  end
end
