# frozen_string_literal: true

require 'rubygems'
require 'bundler'
# Bundler.require
# require 'sinatra'

# require File.expand_path '../app.rb', __dir__

# run Sinatra::Application
# Bundler.require

require 'sequel'
DB = Sequel.connect('sqlite://mcm.db')
Dir['./lib/mcm/**/*.rb'].sort.each do |file|
  require file
end

require 'benchmark'

Benchmark.realtime do
  MCM::Search::Basic.search('C2H4', 'MCM')
end
DB.disconnect
