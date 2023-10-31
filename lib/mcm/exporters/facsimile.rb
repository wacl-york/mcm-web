# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    class Facsimile
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = '.fac'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      def export(species, rxns, rates, root_species, missing_peroxies, peroxies, citation, generic: false)
        # Format sections for export
        species_out = self.class.wrap_lines(species)
        rxns_out = rxns.map { |row| "% #{row[:Rate]} : #{row[:Reaction]} ;\n" }.join
        complex_rates_out = rates.map { |row| "#{row[:Child]} = #{row[:Definition]} ;\n" }.join
        params_out = self.class.wrap_lines(root_species,
                                           starting_char: '* ',
                                           every_line_start: '* ',
                                           every_line_end: ' ;',
                                           ending_char: ' ;',
                                           sep: ' ')
        missing_peroxies_out = self.class.wrap_lines(missing_peroxies,
                                                     starting_char: '* ',
                                                     every_line_start: '* ',
                                                     every_line_end: ' ;',
                                                     ending_char: ' ;',
                                                     sep: ' ')
        peroxy_out = self.class.wrap_lines(peroxies,
                                           starting_char: 'RO2 = ',
                                           ending_char: ';',
                                           sep: ' + ',
                                           max_line_length: 65,
                                           every_line_start: ' ' * 6)

        spacer = "#{'*' * 77} ;\n"
        empty_comment = "*;\n"

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
        if generic
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
        out += peroxy_out
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

      # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize
      def self.wrap_lines(words,
                          max_line_length: 68,
                          starting_char: ' ',
                          ending_char: ';',
                          sep: ' ',
                          every_line_start: '',
                          every_line_end: '')
        out = starting_char
        current_line_length = 0
        words.each do |word|
          to_add = "#{word}#{sep}"
          if (current_line_length + to_add.length) > max_line_length
            out = "#{out[..-2]}#{every_line_end}\n" # remove last unused separating space
            out += every_line_start
            current_line_length = every_line_start.length
          end
          out += to_add
          current_line_length += to_add.length
        end
        if words.count.positive?
          out = (out[..-sep.length]).to_s # remove last unused separating space if added one
        end
        out = "#{out}#{ending_char}\n"
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize
    end
  end
end
