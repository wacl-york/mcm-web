# frozen_string_literal: true

require 'rubygems'
require 'bundler'

require File.expand_path 'app.rb', __dir__

run Sinatra::Application
