require 'rubygems'
require 'git'

desc 'Install needed submodules.'
task :submodules do
  puts '* Downloading sinatra and haml'
  sh 'git submodule init'
  sh 'git submodule update'
end

desc 'Bootstrap your wiki.'
task :bootstrap => :submodules do
  unless (Git.open($path) rescue false)
    puts "* Initializing repository in #{$path}"
    repository = Git.init($path)
    File.open(File.join($path, $homepage), 'w') { |f|
      f << File.read(__FILE__).gsub(/.*__END__/m, '')
    }
    repository.add($homepage)
    repository.commit('Initial commit')
  end
end

__END__
## Welcome on git-wiki

Congratulation, you managed to successfuly run git-wiki!
Feel free to edit this page (double-clik it) and start to use your wiki.
To access the page listing, hit <kbd>CTRL+L</kbd> and <kbd>CTRL+H</kbd> to go to the homepage.
