# frozen_string_literal: true

get '/:mechanism/?' do
  @links = {
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
