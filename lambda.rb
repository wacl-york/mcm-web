# frozen_string_literal: true

require 'rack'
require 'sinatra/lambda_handler'

# Global object that responds to the call method. Stay outside of the handler
# to take advantage of container reuse
$app ||= Rack::Builder.parse_file("#{__dir__}/config.ru").first # rubocop:disable Style/GlobalVars
ENV['RACK_ENV'] ||= 'production'

def lambda_handler(event:, context:)
  Sinatra::LambdaHandler.handler(event: event, context: context, multi_value_headers: true)
end
