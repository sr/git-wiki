#!/usr/bin/rackup1.8
require File.dirname(__FILE__) + "/git-wiki"

<<<<<<< .merge_file_Cnu640
run GitWiki.new(File.expand_path("~/nudocs/mntdocs/"),
  ARGV[2] || ".mdwn", ARGV[3] || "Home")
=======
run GitWiki.new(
  File.expand_path(ARGV[1] || "~/wiki"), 
  ARGV[2] || ".markdown", 
  ARGV[3] || "Home"
)
>>>>>>> .merge_file_qGuND2
