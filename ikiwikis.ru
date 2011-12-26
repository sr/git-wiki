#!/home/albertlash/.rbenv/versions/1.9.3-rc1/bin/rackup
require "./git-wiki"

run GitWiki.new("/home/albertlash/savonix/wikis",
  ARGV[2] || ".mdwn", ARGV[3] || "index")
