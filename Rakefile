require 'rubygems'
require 'git'

task :default => :bootstrap

desc 'Bootstrap your wiki.'
task :bootstrap do
  path = ENV['GIT_WIKI_REPO'] || File.join(ENV['HOME'], 'wiki')
  unless (Git.open(path) rescue false)
    repository = Git.init(path)
    File.open(File.join(path, 'Home'), 'w') { |f|
      f << File.read(__FILE__).gsub(/.*__END__/m, '')
    }
    repository.add('Home')
    repository.commit('Initial commit')
    puts "* Initialized the repository in #{path}"
    puts '* If everything worked as expected, git-wiki will be avalaible at http://0.0.0.0:4567/ in a second'
    puts
    exec "ruby git-wiki.rb"
  end
end

__END__
## Welcome on git-wiki

Congratulation, you managed to successfuly run git-wiki!
Feel free to edit this page (double-clik it) and start to use your wiki.
To access the page listing, hit <kbd>CTRL+L</kbd> and <kbd>CTRL+H</kbd> to go to the homepage.
