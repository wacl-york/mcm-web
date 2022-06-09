# frozen_string_literal: true

get '/' do
  @links = {
    '/reactions' => 'View all reactions',
    '/species' => 'View all species'
  }

  erb :home
end
