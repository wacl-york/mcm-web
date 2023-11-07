# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    class KPP
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = 'kpp'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def export(species, rxns, rates, _root_species, missing_peroxies, peroxies, citation, generic: false)
        #---------------------- Setup
        spacer = ('*' * 58).to_s
        rxns = combine_reactions_with_same_rates(rxns, combine: '+')
        rxns_out = rxns.map.with_index do |row, i|
          "{#{i + 1}.} #{row[:Reaction]} : #{parse_rate_for_kpp(row[:Rate])} ;\n"
        end.join
        complex_rates_out = rates.map { |row| "#{row[:Child]} = #{parse_rate_for_kpp(row[:Definition])}\n" }.join
        species_out = species.map { |x| "#{x} = IGNORE ;\n" }.join
        missing_peroxies_out = MCM::Export.wrap_lines(missing_peroxies,
                                                      starting_char: '    ',
                                                      every_line_start: '    ',
                                                      every_line_end: '',
                                                      ending_char: '',
                                                      max_line_length: 78,
                                                      sep: ' ')
        peroxy_out = MCM::Export.wrap_lines(peroxies.map { |x| "C(ind_#{x})" },
                                            starting_char: '  RO2 = ',
                                            ending_char: '',
                                            every_line_end: ' &',
                                            sep: ' + ',
                                            max_line_length: 78,
                                            every_line_start: ' ' * 6)

        #---------------------- Write to KPP
        # Citation comes first
        out = ''
        out += "{#{spacer} ;\n"
        out += citation.map { |row| "* #{row}\n" }.join
        out += "#{spacer} ;}\n"

        # Globals
        out += "#INLINE F90_GLOBAL\n"
        out += "  REAL(dp)::M, N2, O2, RO2, H2O\n"
        out += "#ENDINLINE {above lines go into MODULE KPP_ROOT_Global}\n"

        # Species
        out += "#INCLUDE atoms \n"
        out += "#DEFVAR\n"
        out += species_out

        # Peroxy radicals
        out += "{ Peroxy radicals. }\n"
        if missing_peroxies.count.positive?
          out += "{ WARNING: The following species do not have SMILES strings in the database. \n"
          out += "           If any of these are peroxy radicals the RO2 sum will be wrong! \n"
          out += missing_peroxies_out # TODO: Shoud this exclude inorganics?
          out += "}\n"
        end
        out += "#INLINE F90_RCONST \n"
        out += peroxy_out

        # Complex rate coefficients
        out += complex_rates_out if generic
        out += "#ENDINLINE \n"
        out += "{above lines go into the SUBROUTINES UPDATE_RCONST and UPDATE_PHOTO}\n"

        # Reactions
        out += "#EQUATIONS\n"
        out += rxns_out

        # Summary
        out + "{ End of Subset. No. of Species = #{species.count}, No. of Reactions = #{rxns.count} }"
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize, Metrics/CyclomaticComplexity

      # rubocop:disable Metrics/AbcSize
      def combine_reactions_with_same_rates(rxns, combine: '+')
        # If there exist multiple reactions (as in the same reactants and products), then they will be combined
        # into one single reaction.
        #
        # Args:
        #
        #   - rxns (list[Hash]): A list of reactions, represented as hashes with keys:
        #     - ReactionID (int)
        #     - Reaction (string)
        #     - Rate (string)
        #   - combine (string): Character to combine rates with.
        #
        # Returns:
        #   - A list of hashes with entries:
        #     - Reaction (string)
        #     - Rate (string)
        #   This will be either the same length as the input (if there are no duplicate reactions)
        #   or shorter (if there are).

        # Firstly ensure all reactions are ordered identically
        rxns.each do |x|
          x[:Split] = x[:Reaction].gsub(/\s+/, '').split('=', 2)
          x[:Reactants] = x[:Split][0].split('+').sort
          x[:Products] = x[:Split][1].split('+').sort
          x[:ReactionOrdered] = [x[:Reactants].join(' + '), x[:Products].join(' + ')].join(' = ')
        end

        # Group into hash of Reaction: [Rate1, Rate2, ...]
        grouped = Hash.new { |h, k| h[k] = [] }
        rxns.each { |x| grouped[x[:ReactionOrdered]] << x[:Rate] }
        # Combine rates
        grouped.map { |h, k| { Reaction: h, Rate: k.join(combine) } }
      end
      # rubocop:enable Metrics/AbcSize

      def parse_rate_for_kpp(rate)
        # Performs necessary conversions on rates as they are stored in the DB (in FACSIMILE format)
        # to be compatible with KPP.
        #
        # Args:
        #   - rate (string): Input rate in FACSIMILE format.
        #
        # Returns:
        #   - A string containing the rate in KPP format.
        rate.gsub(/[<>@]/, '<' => '(', '>' => ')', '@' => '**')
      end
    end
  end
end
