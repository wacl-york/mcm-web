# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
get '/:mechanism/search' do
  q = params[:q]
  output = if q.nil?
             nil
           else
             max_synonyms = DB[:SpeciesSynonyms].max(:NumReferences)

             # The matching score goes from 0 - (2 * max_synonyms), where
             # max_synonyms is the highest number of refefernces any synonym has
             # Scores from (max_synonyms+1) - (2 * max_synonyms) are given
             # to matches that don't use a preceeding wildcard (on Species, Synonym,
             # Smiles, or Inchi)
             # Scores from 0 - max_synonyms include a preceeding wildcard, although
             # it only searches Species and Synonyms, as it doesn't make
             # sense to partially search Smiles and Inchi like this

             ## First level match
             species_trailing = find_species(q, preceeding: false)
                                .select_append(Sequel.lit('CASE WHEN ' \
                                                          'UPPER(Name) LIKE UPPER(?) ' \
                                                          'THEN ? ELSE ? END as score',
                                                          q,
                                                          3 * max_synonyms,
                                                          2 * max_synonyms))
             # Will use the Synonym itself later to populate the search results in case
             # it isn't one of the top 5
             syns_trailing = find_synonym(q, preceeding: false)
             smiles = find_smiles(q)
                      .select_append(Sequel.lit('CASE WHEN ' \
                                                'UPPER(Smiles) LIKE UPPER(?) ' \
                                                'THEN ? ELSE ? END as score',
                                                q,
                                                3 * max_synonyms,
                                                2 * max_synonyms))
             inchi = find_inchi(q)
                     .select_append(Sequel.lit('CASE WHEN ' \
                                               'UPPER(Inchi) LIKE UPPER(?) ' \
                                               'THEN ? ELSE ? END as score',
                                               q,
                                               3 * max_synonyms,
                                               2 * max_synonyms))

             first_order_matches = species_trailing
                                   .union(syns_trailing.select(:Species,
                                                               Sequel.lit('CASE WHEN UPPER(Synonym) LIKE UPPER(?) ' \
                                                                          'THEN NumReferences+? ' \
                                                                          'ELSE NumReferences+? ' \
                                                                          'END as score',
                                                                          q,
                                                                          max_synonyms * 2,
                                                                          max_synonyms)))
                                   .union(smiles)
                                   .union(inchi)

             ## Second level match - only for Species and Synonym
             species_full = find_species(q, preceeding: true)
                            .select_append(Sequel.lit("#{max_synonyms} as score"))
             syns_full = find_synonym(q, preceeding: true)
             second_order_matches = species_full.union(syns_full.select(:Species,
                                                                        Sequel.lit('NumReferences as score')))

             # Only return a single result per species - its highest score
             all_matches = first_order_matches
                           .union(second_order_matches)
                           .group(:Name)
                           .select(:Name, Sequel.lit('max(score) as score'))

             # We have a Species name ready to return, but we also want to display
             # its top 5 synonyms, plus any additional synonym that matched the search
             # but isn't necessarily in the top 5 most commonly used

             # First find the top 5 synonyms per species
             syns5 = all_matches
                     .from_self(alias: :matches)
                     .left_join(:SpeciesSynonyms, { Species: :Name }, table_alias: :syn)
                     .select_append(Sequel.function(:row_number).over(partition: :Species,
                                                                      order: Sequel.desc(:NumReferences)).as(:n))
                     .from_self(alias: :m3) # 'where' gets applied at wrong stage without this
                     .where { n <= 5 }
                     .from_self(alias: :m4)

             # Next find the top matched synonym
             matched_synonyms = syns_trailing
                                .select_append(Sequel.lit('CASE WHEN UPPER(Synonym) LIKE UPPER(?) ' \
                                                          'THEN NumReferences+? ELSE NumReferences+? END as score',
                                                          q,
                                                          max_synonyms * 2,
                                                          max_synonyms))
                                .union(syns_full.select_append(Sequel.lit('NumReferences as score')))
                                .select_append(Sequel.function(:row_number).over(partition: :Species,
                                                                                 order: Sequel.desc(:score)).as(:n))
                                .from_self(alias: :m5)
                                .where(n: 1)
                                .select(:Species, :Synonym, :score)
                                .select_append(Sequel.lit('Species as Name'))

             # Combine the top 5 synonyms and the top matched synonym in case the search matched a synonym that wasn't
             # # in top 5, still want to display it in the results box so the user knows why it was returned
             syns_all = syns5.full_join(matched_synonyms, %i[Name Species score Synonym])
             # Collapse synonyms to single comma separated string
             # NB: GROUP_CONCAT is SQLite specific, but the string_agg extension doesn't work here

             syns_all
               .from_self(alias: :m7)
               .group(Sequel[:m7][:Name], :score)
               .select(Sequel[:m7][:Name], :score,
                       Sequel.lit('CASE WHEN
                                  GROUP_CONCAT(Synonym, \', \') IS NULL
                                  THEN \'\'
                                  ELSE GROUP_CONCAT(Synonym, \', \')
                                  END').as(:Synonyms))
               .inner_join(:Species, Sequel.lit('m7.Name = Species.Name'))
               # Restrict to the selected mechanism. NB: would likely be more efficient to filter earlier
               # when searching for each matching condition (synonym, name, etc...), but it makes the code more
               # legible do it in one location
               .inner_join(:SpeciesMechanisms, [%i[Name Name], [:Mechanism, @mechanism]])
               .select_append(:Smiles, :Inchi)
               .order(Sequel.desc(:score))
           end
  content_type :json
  output.all.to_json
end
# rubocop:enable Metrics/BlockLength

def find_species(term, preceeding: false)
  search_pattern = "#{term}%"
  search_pattern = "%#{search_pattern}" if preceeding
  DB[:species]
    .where(Sequel.ilike(:Name, search_pattern))
    .select(:Name)
end

def find_synonym(term, preceeding: false)
  search_pattern = "#{term}%"
  search_pattern = "%#{search_pattern}" if preceeding
  DB[:speciessynonyms]
    .where(Sequel.ilike(:Synonym, search_pattern))
end

def find_smiles(term)
  search_pattern = "#{term}%"
  DB[:species]
    .where(Sequel.ilike(:Smiles, search_pattern))
    .select(:Name)
end

def find_inchi(term)
  search_pattern = "#{term}%"
  DB[:species]
    .where(Sequel.ilike(:Inchi, search_pattern))
    .select(:Name)
end
