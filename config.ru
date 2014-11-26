require 'rubygems'
require 'bundler'
require "rack-timeout"

use Rack::Timeout          # Call as early as possible so rack-timeout runs before all other middleware.
Rack::Timeout.timeout = 29

Bundler.require
require './snotel'

map "/assets" do
    run Rack::Directory.new("./assets")
end

run Snotel