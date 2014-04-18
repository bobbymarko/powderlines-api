require 'rubygems'
require 'bundler'

Bundler.require
require './snotel'

map "/assets" do
    run Rack::Directory.new("./assets")
end

run Snotel