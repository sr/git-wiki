#!/usr/bin/env ruby
__DIR__ = File.dirname(__FILE__)

require File.join(__DIR__, "git-wiki")

set :public, File.join(__DIR__, "public")
set :port,  4567
set :env,   :production
disable :run, :reload

run Sinatra.application
