module GitWiki
  class Page
    def self.find_all
      return [] if repository.tree.contents.empty?

      all_blobs = collect_blobs_from_tree(repository.tree)

      all_blobs.flatten.collect do |blob|
        new(blob)
      end
    end

    def self.collect_blobs_from_tree(tree, path=nil)
      path = (path.nil? || tree.name.nil?) ? '' : path+'/'+tree.name
      tree.contents.inject([]) do |blobs, file|
        if file.is_a? Grit::Blob
          add_path_to_blob(file, path+'/'+file.name)
          blobs.push file
        elsif file.is_a? Grit::Tree
          blobs.concat collect_blobs_from_tree(file, path)
        end
        blobs
      end
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
      blob = repository.tree/(page_name + extension)
      add_path_to_blob(blob, page_name + extension)  if blob
      blob
    end
    private_class_method :find_blob

    def self.add_path_to_blob(blob, path)
      blob.instance_eval do
        def path
          @path
        end
        def path=(new_path)
          @path = new_path
        end
      end
      blob.path = path
    end
    private_class_method :add_path_to_blob

    def self.create_blob_for(page_name)
      blob = Grit::Blob.create(repository, {
        :name => page_name + extension,
        :data => ""
      })
      add_path_to_blob(blob, page_name + extension)  if blob
      blob
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
      @blob.path.gsub(/#{File.extname(@blob.name)}$/, '').gsub(/^\//,'')
    end

    def short_name
      File.basename(@blob.name).gsub(/#{File.extname(@blob.name)}$/, '')
    end

    def parent_directories
      File.dirname(name).split(/\//).inject([[],[]]){ |collection, dirname|
        parents, paths = collection
        parents.push(dirname)
        paths.push(parents.join('/'))
        [parents, paths]
      }[1]
    end

    def content
      @blob.data
    end

    def update_content(new_content)
      return if new_content == content
      system("mkdir -p '#{File.dirname(file_name)}'");
      File.open(file_name, "w") { |f| f << new_content }
      add_to_index_and_commit!
    end

    private
      def add_to_index_and_commit!
        Dir.chdir(self.class.repository.working_dir) {
          self.class.repository.add(@blob.path)
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
end