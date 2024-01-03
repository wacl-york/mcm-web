# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    class SpeciesTSV
      CONTENT_TYPE = 'text/csv'
      FILE_EXTENSION = 'tsv'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      def export(species, _rxns, _complex_rates, _photo_rates, _root_species, _missing_peroxies, _peroxies, citation,
                 _generic)
        # Retrieve species information from DB
        species_fmt = DB[:Species]
                      .where(Name: species)

        # Get the species fields ordered correctly
        col_order = %w[Name Smiles Inchi InchiKey Mass Excited PeroxyRadical]
        species_out = species_fmt.map do |x|
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
    end
  end
end
