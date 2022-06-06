# frozen_string_literal: true

get '/login' do
  require_authentication

  erb :login
end
