# frozen_string_literal: true

get '/search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               DB[:species].where(Sequel.like(:Name, "%#{q}%"))
             end

  erb :search
end
