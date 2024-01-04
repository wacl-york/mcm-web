# frozen_string_literal: true

module MCM
  module Export
    # Exporter into TSV format
    class SpeciesTSV
      CONTENT_TYPE = 'text/csv'
      FILE_NAME = 'mcm_export_species.tsv'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      def export(species, _rxns, _complex_rates, _photo_rates, _root_species, _missing_peroxies, _peroxies, citation,
                 _generic)
        # Retrieve species information from DB
        species_query = DB[:Species]
                        .where(Name: species)
        synonyms = get_synonyms(species_query)
        species_query = species_query.left_join(synonyms, [:Name])

        # Get the species fields ordered correctly
        col_order = %w[Name Smiles Inchi InchiKey Mass Excited PeroxyRadical Synonyms]
        species_out = species_query.map do |x|
          row_ordered = col_order.map { |col| x[col.to_sym] }
          row_ordered.join("\t")
        end

        # Format into TSV
        header = "#{col_order.join("\t")}\n"
        species_out = species_out.join("\n")

        #---------------------- Write TSV
        # Citation comes first
        out = ''
        out += citation.map { |row| "* #{row}\n" }.join
        out += header
        out + species_out
        #---------------------- End write TSV
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Metrics/MethodLength

      def get_synonyms(data)
        # Retrieves the most common 5 synonyms per specified species
        # If no synonyms are found an empty string is returned, if < 5 synoyms
        # are found then the string only contains these elements (no padding)
        #
        # Args:
        #   - data: Sequel dataset with a Name field
        #
        # Returns:
        #   - A Sequel dataset with 2 fields:
        #     - Name: the species name as in the input
        #     - Synonyms: A comma-delimited string of 0-5 synonyms
        MCM::Database.get_top_5_synonyms(data)
                     .group(:Name)
                     .select(Sequel[:Name].as(:Name),
                             Sequel.lit('CASE WHEN
                                        GROUP_CONCAT(Synonym, \'; \') IS NULL
                                        THEN \'\'
                                        ELSE GROUP_CONCAT(Synonym, \'; \')
                                        END').as(:Synonyms))
      end
    end
  end
end
