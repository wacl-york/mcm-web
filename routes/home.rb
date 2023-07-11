# frozen_string_literal: true

get '/:mechanism?/?' do
  # TODO: redirect instead?
  # TODO possible to apply this in one place to all routes?
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM
  @links = {
    '/export' => 'Export a mechanism subset'
  }

  erb :home
end
