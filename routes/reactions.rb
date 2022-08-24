# frozen_string_literal: true

get '/reactions' do
  n = params[:n]
  n = 10 if n.nil?

  @reactions = DB[:reactionswide].limit(n)
  @n_reactions = n

  erb :reactions
end
