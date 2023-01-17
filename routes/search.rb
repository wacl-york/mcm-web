# frozen_string_literal: true

get '/search' do
  erb :search
end

# rubocop:disable Metrics/BlockLength
get '/search-synonym' do
  q = params[:q]
  species = if q.nil?
              nil
            else
              # TODO: can add Species and Inchi later
              species = DB[:species]
                        .where(Sequel.ilike(:Name, "%#{q}%"))
                        .select(Sequel.lit('Name,
                                           1 as weight,
                                           (SELECT MAX(NumReferences)+1 FROM SpeciesSynonyms) as NumReferences'))
              synonyms = DB[:speciessynonyms]
                         .where(Sequel.ilike(:Synonym, "%#{q}%"))
                         .select(Sequel.lit('Species as Name, 0.5 as weight, NumReferences'))
              # Score results by number of references, although matches in formula name will always have higher weight
              matches = species
                        .union(synonyms)
                        .group(:Name)
                        .select(:Name, Sequel.lit('max(weight * NumReferences) as score'))

              # Add on the top n synonyms for display
              syns_all = matches
                         .from_self(alias: :matches)
                         .join(:SpeciesSynonyms, { Species: :Name }, table_alias: :syn)
                         .select_append(Sequel.function(:row_number).over(partition: :Species,
                                                                          order: Sequel.desc(:NumReferences)).as(:n))

              # Limit to 5 most common synonyms
              # NB: can't get this working in Sequel unless explicitly create subquery like this
              syns5 = syns_all
                      .from_self(alias: :m3)
                      .where { n <= 5 }

              # Collapse synonyms to single string
              # NB: GROUP_CONCAT is SQLite specific, but the string_agg extension doesn't work here
              syns5
                .from_self(alias: :m4)
                .group(:Species)
                .select(:Species, :score, Sequel.lit('GROUP_CONCAT(Synonym, \', \')').as(:Synonyms))
                .order(Sequel.desc(:score))
            end
  content_type :json
  species.all.to_json
end
# rubocop:enable Metrics/BlockLength
