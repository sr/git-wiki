#!/usr/bin/rackup1.8
require File.dirname(__FILE__) + "/git-wiki"

run GitWiki.new(File.expand_path("~/wikis/"),
  ARGV[2] || ".mdwn", ARGV[3] || "Index")
