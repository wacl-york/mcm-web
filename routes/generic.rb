# frozen_string_literal: true

get '/?:mechanism?/rates/generic' do
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM
  @rates = DB[:GenericRatesWeb]
           .join(Sequel[:Tokens], Token: :Token)
  erb :generic
end
