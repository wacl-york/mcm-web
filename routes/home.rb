# frozen_string_literal: true

get '/' do
  @links = {
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
