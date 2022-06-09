# frozen_string_literal: true

get '/reactions' do
  n = params[:n]
  
  if n.nil?
    n = 10
  end

  @reactions = DB[:reactionswide].limit(n)
  @n_reactions = n

  erb :reactions
end
