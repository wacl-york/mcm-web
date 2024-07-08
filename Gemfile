# frozen_string_literal: true

ruby '~> 3.2'

source 'https://rubygems.org'

group :test do
  gem 'benchmark'
  gem 'capybara', require: ['capybara/dsl', 'capybara/rspec/matcher_proxies']
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-github'
end

group :development do
  gem 'bundler-audit'
  gem 'rubocop'
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', '~> 2.0', require: false
  gem 'rubocop-sequel', require: false
  gem 'webrick'
end

gem 'aws-sdk-rds', '~> 1'
gem 'aws-sdk-sns', '~> 1'
gem 'erubi'
gem 'nokogiri', '>= 1.16.5'
gem 'public_suffix', '~> 5.0'
gem 'puma', '>= 6.4.2'
gem 'rack'
gem 'rest-client'
gem 'sequel'
gem 'sinatra', ['~> 2', '!= 2.1.0']
gem 'sinatra-contrib', require: ['sinatra/capture', 'sinatra/config_file', 'sinatra/content_for', 'sinatra/cookies']
gem 'sqlite3'

source 'https://gem.fury.io/universityofyork/' do
  gem 'aws-sessionstore-dynamodb', '~> 1'
  gem 'uoy-faculty_aws', '>= 0.9.0', require: ['faculty_aws/notify_devs', 'faculty_aws/db_connector']
  gem 'uoy-faculty-helpers', require: 'faculty_helpers'
  gem 'uoy-faculty-rbac', require: ['rbac', 'faculty_rbac/sinatra']
  gem 'uoy-faculty-sinatra', '~> 4.5', require: ['rack/combined_logger', 'sinatra/faculty']
  gem 'uoy-faculty-sinatra-aws', '~> 3.0', require: ['sinatra/faculty/aws', 'sinatra/faculty/aws_alternate_logs']

  group :test do
    gem 'uoy-faculty-spec-helpers', require: 'spec_helpers'
  end
end
