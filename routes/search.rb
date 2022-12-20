# frozen_string_literal: true

get '/search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               species = DB[:species].where(Sequel.ilike(:Name, "%#{q}%")).select(:Name)
               synonyms = DB[:speciessynonyms].where(Sequel.ilike(:Synonym, "%#{q}%")).select(:Species)
               species.union(synonyms)
             end
  erb :search
end
