#!/var/lib/gems/1.9.1/bin/rackup
require "./git-wiki"

run GitWiki.new("/home/albertlash/wikis/",
  ARGV[2] || ".mdwn", ARGV[3] || "index")
