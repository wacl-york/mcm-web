# frozen_string_literal: true

get '/:mechanism?/?' do
  # TODO redirect instead?
  @mechanism = params[:mechanism] ? params[:mechanism] : 'mcm'
  @links = {
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
