require 'rubygems'
require 'git'

$path = File.expand_path(ENV['GIT_WIKI_REPOSITORY'] || File.join(ENV['HOME'], 'wiki'))
$homepage     = 'Home'
$ruby         = `which ruby`.chomp
$pid_file     = '/var/run/git-wiki'
$server       = 'mongrel'
$environment  = 'production'

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

desc 'Install git-wiki as a daemon and run it at boot.'
task :daemonize => 'daemon:at_boot' do
  sh 'sudo /etc/init.d/git-wiki start' do |successful, _|
    if successful
      puts '=> Point your browser at http://0.0.0.0:4567 and start to use your wiki!'
    else
      'Something went wrong.'
    end
  end
end

namespace :daemon do
  task :install do
    File.open('git-wiki.d', 'w') do |f|
      f << File.read('git-wiki.d.in') % [$ruby, ENV['USER'],
        Dir.pwd, $path, $pid_file, $environment, $server]
    end
    sh 'sudo cp -f git-wiki.d /etc/init.d/git-wiki'
    sh 'sudo chmod +x /etc/init.d/git-wiki'
    sh 'rm git-wiki.d'
  end

  task :at_boot => :install do
    sh 'sudo /usr/sbin/update-rc.d git-wiki defaults'
  end
end

__END__
## Welcome on git-wiki

Congratulation, you managed to successfuly run git-wiki!
Feel free to edit this page (double-clik it) and start to use your wiki.
To access the page listing, hit <kbd>CTRL+L</kbd> and <kbd>CTRL+H</kbd> to go to the homepage.
