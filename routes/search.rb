# frozen_string_literal: true

get '/search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               species = DB[:species]
                         .where(Sequel.ilike(:Name, "%#{q}%"))
                         .select(Sequel.lit('Name, 1 as priority'))
               synonyms = DB[:speciessynonyms]
                          .where(Sequel.ilike(:Synonym, "%#{q}%"))
                          .select(Sequel.lit('Species as Name, 2 as priority'))
               # Again can't distinct when have multiple columns in sqlite
               species.union(synonyms).order(:priority).select(:Name).distinct
             end
  erb :search
end
