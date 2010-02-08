#!/usr/bin/rackup1.8
require File.dirname(__FILE__) + "/git-wiki"

run GitWiki.new(File.expand_path("~/nudocs/mntdocs/"),
  ARGV[2] || ".mdwn", ARGV[3] || "Home")
