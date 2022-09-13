# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require
require 'sinatra'

require File.expand_path 'app.rb', __dir__

run Sinatra::Application
