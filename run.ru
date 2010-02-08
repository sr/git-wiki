#!/usr/bin/env rackup
#\ -p 8787
require File.dirname(__FILE__) + "/git-wiki"

run GitWiki.new(File.expand_path(ARGV[1] || "~/wiki"),
  ARGV[2] || ".markdown", ARGV[3] || "Home")
