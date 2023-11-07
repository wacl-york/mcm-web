# frozen_string_literal: true

module MCM
  module Search
    # Basic seach functionalities
    module Basic
      module_function

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def search(term, mechanism)
        # Searches the database for species matching a given query term.
        #
        # Hits are returned with a score from 0 - N (where N is 3 * max references a synonym has) according to
        # using the following criteria:
        #   - 'exact match': Querying 'CH4' returns 'CH4' but not 'XCH4' or 'CH42'
        #   - 'starting match': Querying 'CH4' returns 'CH42', but not 'XCH4', in addition to exact match results
        #   - 'partial match': Querying 'CH4' returns 'XCH4', in addition to starting match results
        #
        # Scoring ranking:
        #   - Exact match on species name: 3N
        #   - Exact match on smiles: 3N
        #   - Exact match on inchi: 3N
        #   - Exact match on synonym: 2N + number of references to that synonym
        #   - Starting match on species name: 2N
        #   - Starting match on smiles: 2N
        #   - Starting match on inchi: 2N
        #   - Starting match on synonym: N + number of references to that synonym
        #   - Partial match on species name: N
        #   - Partial match on smiles: N
        #   - Partial match on synonym: number of references to that synonym
        #
        # NB: partial matches aren't counted as hits for InChI
        #
        # Args:
        #   - term (String): The search query
        #   - mechanism (String): The mechanism to search
        #
        # Returns:
        #   A Sequel Dataset with 1 row per species and columns:
        #     - Name: Species name
        #     - Synonyms: CSV string of top 5 synonyms + any matching synonym
        #     - Score: Score relating to how good a match this is, higher is better
        #     - Smiles: The species' smiles string
        #     - Inchi: The species' InChI string
        #
        max_synonyms = DB[:SpeciesSynonyms].max(:NumReferences)

        # Run all searches
        results_species = find_species(term, max_synonyms)
        results_synonyms = find_synonym(term, max_synonyms)
        results_smiles = find_smiles(term, max_synonyms)
        results_inchi = find_inchi(term, max_synonyms)
        results_all = results_species
                      .union(results_synonyms)
                      .union(results_smiles)
                      .union(results_inchi)

        # Calculate search scores and reduce to one match per species (its highest match)
        results_all = add_multipliers(results_all, term)
        results_all = calculate_highest_score_per_species(results_all)

        # For each matched species, want to display the top 5 synonyms as well as any synonyms that matched
        syns_five = get_top_5_synonyms(results_all)
        results_all = results_all.full_join(syns_five, %i[Name Synonym]) # One row per species-synonym
        results_all = collapse_synonyms(results_all) # Collapse to one row per species

        # Retrieve species metadata and restrict to the selected mechanism
        results_all
          .inner_join(:Species, [:Name])
          .inner_join(:SpeciesMechanisms, [:Name])
          .where(Mechanism: mechanism)
          .select_append(:Smiles, :Inchi)
          .order(Sequel.desc(:score))
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def find_species(term, base_score)
        DB[:species]
          .where(Sequel.ilike(:Name, "%#{term}%"))
          .select_append(Sequel.lit('NULL as Synonym'))
          .select_append(Sequel.lit('? as Slope', base_score))
          .select_append(Sequel.lit('? as Intercept', base_score))
          .from_self(alias: :species)
          .select(:Name, :Synonym, Sequel[:Name].as(:SearchField), :Slope, :Intercept)
      end

      def find_synonym(term, base_score)
        DB[:speciessynonyms]
          .where(Sequel.ilike(:Synonym, "%#{term}%"))
          .select_append(Sequel.lit('? as Slope', base_score))
          .from_self(alias: :syn)
          .select(Sequel[:Species].as(:Name), :Synonym, Sequel[:Synonym].as(:SearchField), :Slope,
                  Sequel[:NumReferences].as(:Intercept))
      end

      def find_smiles(term, base_score)
        DB[:species]
          .where(Sequel.ilike(:Smiles, "%#{term}%"))
          .select_append(Sequel.lit('NULL as Synonym'))
          .select_append(Sequel.lit('? as Slope', base_score))
          .select_append(Sequel.lit('? as Intercept', base_score))
          .from_self(alias: :smiles)
          .select(:Name, :Synonym, Sequel[:Smiles].as(:SearchField), :Slope, :Intercept)
      end

      def find_inchi(term, base_score)
        DB[:species]
          .where(Sequel.ilike(:Inchi, "#{term}%"))
          .select_append(Sequel.lit('NULL as Synonym'))
          .select_append(Sequel.lit('? as Slope', base_score))
          .select_append(Sequel.lit('? as Intercept', base_score))
          .from_self(alias: :inchi)
          .select(:Name, :Synonym, Sequel[:Inchi].as(:SearchField), :Slope, :Intercept)
      end

      def add_multipliers(data, query)
        # Adds score multipliers depending on whether the match was full, starting, or partial
        #
        # Args:
        #   - data (Sequel Dataset): Dataset with columns:
        #     - Name: Species name
        #     - Synonym: Synonym that was matched on if applicable, else NULL
        #     - SearchField: The field that matched with the search query
        #     - Slope: The multiplicative constant
        #     - Intercept: The offset
        #   - query (String): The search query
        #
        # Returns:
        #   The same input but with a new column called 'Multiplier', which will get
        #   multiplied by the Slope and added to the Intercept to provide the match's
        #   overall score.
        data.select_append(Sequel.lit('CASE ' \
                                      'WHEN UPPER(SearchField) LIKE UPPER(?) THEN ? ' \
                                      'WHEN UPPER(SearchField) LIKE UPPER(?) THEN ? ' \
                                      'ELSE ? ' \
                                      'END as multiplier',
                                      query, 2, "#{query}%", 1, 0))
            .from_self(alias: :mult)
      end

      def calculate_highest_score_per_species(data)
        # Calculates the score for a set of matches, returning only the
        # highest score for each Species.
        #
        # The score calculated by multiplying a constant
        # by a slope and added to an offset.
        # In SQLite you can get the top row for a group simply
        # by grouping by and selecting an aggregate function.
        #
        # Args:
        #   - data (Sequel Dataset): Dataset with columns:
        #     - Name: Species name
        #     - Synonym: Synonym that was matched on if applicable, else NULL
        #     - SearchField: The field that matched with the search query
        #     - Slope: The multiplicative constant
        #     - Intercept: The offset
        #
        # Returns:
        #   A Sequel Dataset with 3 columns:
        #     - Name: Species name
        #     - Synonym: Synonym that was matched on if applicable, else NULL
        #     - Score: The score
        data
          .group(:Name)
          .select(:Name,
                  :Synonym,
                  Sequel.lit('max(Intercept + Slope * multiplier) as score')) # Can't do multiplication in Sequel
          .from_self(alias: :matches)
      end

      def get_top_5_synonyms(data)
        # TODO: put in DB lib
        # Retrieves the top 5 synonyms for a species
        #
        # Args:
        #   - data (Sequel Dataset): Dataset that at least has a 'Name' column with the species name
        #
        # Returns:
        #   A Sequel Dataset with Name and Synonym
        data.select(:Name).from_self(alias: :input)
            .left_join(:SpeciesSynonyms, { Species: :Name }, table_alias: :syn)
            .select_append(
              Sequel.function(:row_number)
              .over(partition: :Species, order: Sequel.desc(:NumReferences)).as(:n)
            )
            .from_self(alias: :m3) # 'where' gets applied at wrong stage without this
            .where { n <= 5 }
            .from_self(alias: :m4)
            .select(:Name, Sequel[:m4][:Synonym])
      end

      def collapse_synonyms(data)
        # Collapses long dataset with 1 row per Species-Synonym into to
        # 1 row per Species with the Synonyms concatenated into 1 string
        #
        # NB: GROUP_CONCAT is SQLite specific, but the string_agg extension doesn't work here
        #
        # Args:
        #   - data (Sequel Dataset): A dataset with 1 row per species-synonym and 3 columns:
        #     - Name
        #     - Synonym
        #     - Score
        #
        # Returns:
        #   A dataset with 1 row per species with 3 columns:
        #     - Name
        #     - Score
        #     - Synonyms (a CSV string)
        data
          .group(:Name)
          .select(Sequel[:Name].as(:Name),
                  Sequel.lit('max(score)').as(:score),
                  Sequel.lit('CASE WHEN
                              GROUP_CONCAT(Synonym, \', \') IS NULL
                              THEN \'\'
                              ELSE GROUP_CONCAT(Synonym, \', \')
                              END').as(:Synonyms))
      end
    end
  end
end
