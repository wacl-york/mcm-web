# frozen_string_literal: true

get '/search' do
  q = params[:q]
  
  if q.nil?
    @species = nil
  else
    @species = DB[:species].where(Sequel.like(:Name, "%#{q}%"))
  end

  erb :search
end
