# frozen_string_literal: true

ruby '~> 2.7.1'

source 'https://rubygems.org'

group :test do
  gem 'capybara'
  gem 'rack-test'
  gem 'rspec'
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
gem 'pg', '< 1.3'
gem 'rack', '~> 2.2'
gem 'rest-client'
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'sinatra', ['~> 2', '!= 2.1.0']
gem 'sinatra-contrib', require: ['sinatra/capture', 'sinatra/config_file', 'sinatra/content_for']

source 'https://gem.fury.io/universityofyork/' do
  gem 'aws-sessionstore-dynamodb', '~> 1'
  gem 'uoy-faculty_aws', '>= 0.9.0', require: ['faculty_aws/notify_devs', 'faculty_aws/db_connector']
  gem 'uoy-faculty-helpers', require: 'faculty_helpers'
  gem 'uoy-faculty-rbac', require: ['rbac', 'faculty_rbac/sinatra']
  gem 'uoy-faculty-sinatra', '~> 4', require: 'sinatra/faculty'
  gem 'uoy-faculty-sinatra-aws', '~> 2.0', require: 'sinatra/faculty/aws'

  group :test do
    gem 'uoy-faculty-spec-helpers', require: 'spec_helpers'
  end
end
