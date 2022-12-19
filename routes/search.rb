# frozen_string_literal: true

get '/search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               species = DB[:species].where(Sequel.like(:Name, "%#{q}%")).select(:Name)
               synonyms = DB[:speciessynonyms].where(Sequel.like(:Synonym, "%#{q}%")).select(:Species)
               species.union(synonyms)
             end
  erb :search
end
