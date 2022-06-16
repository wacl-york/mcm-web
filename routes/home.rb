# frozen_string_literal: true

get '/' do
  @links = {
    '/reactions' => 'View all reactions',
    '/species' => 'View all species',
    '/search' => 'Search for a species',
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
