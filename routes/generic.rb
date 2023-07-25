# frozen_string_literal: true

get '/:mechanism/rates/generic' do
  @rates = DB[:GenericRatesWeb]
           .join(Sequel[:Tokens], Token: :Token)
  erb :generic
end
