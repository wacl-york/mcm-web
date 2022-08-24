# frozen_string_literal: true

get '/species' do
  n = params[:n]
  n = 10 if n.nil?

  @species = DB[:species].limit(n).order(:Name)
  @n_species = n

  erb :species
end
