# frozen_string_literal: true

get '/species' do
  n = params[:n]
  
  if n.nil?
    n = 10
  end

  @species = DB[:species].limit(n).order(:Name)
  @n_species = n

  erb :species
end
