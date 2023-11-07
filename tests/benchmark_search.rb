# frozen_string_literal: true

require 'bundler'
require 'rack/test'
ENV['RACK_ENV'] = 'test'
require File.expand_path '../app.rb', __dir__
require 'benchmark'

res = Benchmark.realtime do
  MCM::Search::Basic.search('C2H4', 'MCM').all
end
puts "Time taken for C2H4: #{res}s"
res = Benchmark.realtime do
  MCM::Search::Basic.search('CH', 'MCM').all
end
puts "Time taken for CH: #{res}s"
DB.disconnect
