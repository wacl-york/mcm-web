# frozen_string_literal: true

get '/' do
  @links = {
    '/search' => 'Search for a species',
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
