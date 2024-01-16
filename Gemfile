# frozen_string_literal: true

ruby '~> 2.7.1'

source 'https://rubygems.org'

group :test do
  gem 'benchmark'
  gem 'capybara'
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-github', '~> 2.3'
end

group :development do
  gem 'bundler-audit'
  gem 'rubocop'
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-sequel', require: false
end

gem 'aws-sdk-rds', '~> 1'
gem 'aws-sdk-sns', '~> 1'
gem 'erubi'
gem 'public_suffix', '~> 5.0'
gem 'puma', '>= 6.4.2'
gem 'rack', ['~> 2.2.6', '>= 2.2.6.3']
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
  gem 'uoy-faculty-sinatra-aws', '~> 2.5', require: ['sinatra/faculty/aws', 'sinatra/faculty/aws_alternate_logs']

  group :test do
    gem 'uoy-faculty-spec-helpers', require: 'spec_helpers'
  end
end
