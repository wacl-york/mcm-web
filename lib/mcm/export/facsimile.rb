# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    class Facsimile
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = 'fac'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def export(species, rxns, complex_rates, _photo_rates, root_species, missing_peroxies, peroxies, citation,
                 generic)
        #---------------------- Setup
        spacer = "#{'*' * 77} ;\n"
        empty_comment = "*;\n"

        # Reactions
        rxns_out = rxns.map { |row| "% #{row[:Rate]} : #{row[:Reaction]} ;\n" }.join

        # Complex rates
        complex_rates_out = complex_rates.map { |row| "#{row[:Child]} = #{row[:Definition]} ;\n" }.join

        # Define the species used in this submechanism
        species_out = MCM::Export.wrap_lines(species)

        # The name of the root-level VOCs are provided
        params_out = MCM::Export.wrap_lines(root_species,
                                            starting_char: '* ',
                                            every_line_start: '* ',
                                            every_line_end: ' ;',
                                            ending_char: ' ;',
                                            sep: ' ')

        # Peroxy radicals are provided by a proxy RO2 sum
        peroxy_out = MCM::Export.wrap_lines(peroxies,
                                            starting_char: 'RO2 = ',
                                            ending_char: ';',
                                            sep: ' + ',
                                            max_line_length: 65,
                                            every_line_start: ' ' * 6)

        # There's a warning about species in the RO2 sum that don't have a mass
        missing_peroxies_out = MCM::Export.wrap_lines(missing_peroxies,
                                                      starting_char: '* ',
                                                      every_line_start: '* ',
                                                      every_line_end: ' ;',
                                                      ending_char: ' ;',
                                                      sep: ' ')

        #---------------------- Write Facsimile file
        # Citation comes first
        out = ''
        out += spacer
        out += citation.map { |row| "* #{row}\n" }.join
        out += spacer

        # Selected species + all species in this mechanism
        out += spacer
        out += params_out
        out += empty_comment
        out += "* Variable definitions. All species are listed here.;\n"
        out += empty_comment
        out += "VARIABLE\n"
        out += species_out
        out += spacer

        # Complex rate coefficients
        if generic && complex_rates.count.positive?
          out += empty_comment
          out += "* Generic Rate Coefficients ;\n"
          out += empty_comment
          out += "* Complex reactions ;\n"
          out += empty_comment
          out += complex_rates_out
        end

        # Peroxies
        out += spacer
        out += "* Peroxy radicals. ;\n*;\n"
        if missing_peroxies.count.positive?
          out += "* WARNING: The following species do not have SMILES strings in the database. ;\n"
          out += "*          If any of these are peroxy radicals the RO2 sum will be wrong!!! ;\n"
          out += missing_peroxies_out # TODO: Shoud this exclude inorganics?
        end
        out += spacer
        out += empty_comment
        out += peroxy_out if peroxies.length.positive?
        out += empty_comment

        # Reactions
        out += "* Reaction definitions. ;\n"
        out += empty_comment
        out += rxns_out
        out += empty_comment

        # Summary
        out + "* End of Subset. No. of Species = #{species.count}, No. of Reactions = #{rxns.count} ;"
        #---------------------- End write facsimile file
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
