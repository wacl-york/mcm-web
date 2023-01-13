# frozen_string_literal: true

get '/search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               species = DB[:species]
                         .where(Sequel.ilike(:Name, "%#{q}%"))
                         .select(Sequel.lit('Name, 1 as priority, 1 as NumReferences'))
               synonyms = DB[:speciessynonyms]
                          .where(Sequel.ilike(:Synonym, "%#{q}%"))
                          .select(Sequel.lit('Species as Name, 2 as priority, NumReferences'))
               # Return results first by whether the species itself was matched, and then the number
               # of references for a species' most common synonym
               species
                 .union(synonyms)
                 .group(:Name)
                 .select(Sequel.lit('Name, min(priority) as priority, max(NumReferences) as NumReferences'))
                 .order(:priority, Sequel.desc(:NumReferences))
             end
  erb :search
end
