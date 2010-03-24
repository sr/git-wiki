require "rubygems"
require File.dirname(__FILE__) + "/git-wiki"

run GitWiki.new(File.expand_path("~/wiki"), ".markdown", "Home")