# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    # rubocop:disable Metrics/ClassLength
    class KPP
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = 'kpp'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def export(species, rxns, complex_rates, photo_rates, _root_species, missing_peroxies, peroxies, citation,
                 generic: false)
        #---------------------- Setup
        # Citation
        citation_fmt = citation.map { |row| "* #{row}" }.join("\n")
        citation_out = "{#{'*' * 58} ;\n#{citation_fmt}\n#{'*' * 58} ;}\n"

        # Photolysis rates need to be both defined and have their equation generated from the raw parameters and parsed
        # Create a lookup table mapping the MCM J number into its 1-based index for use in a Fortran array
        photo_lookup_table = {}
        photo_rates.each.with_index { |x, i| photo_lookup_table["J<#{x[:J]}>"] = "J<#{i + 1}>" }

        # Generate the definition and parsed rate equations
        photo_defs_out = "  REAL(dp), DIMENSION(#{photo_rates.count}) :: J\n"
        photo_rates_out = photo_rates.map do |row| # Ditto .join("\n") comment as complex_rates_out
          rate = form_photolysis_equation(row)
          rate_parsed = parse_rate_for_kpp(rate, photo_lookup_table)
          "#{rate_parsed}\n"
        end.join

        # Reactions need several conversions to be usable in KPP
        #   1. Combine identical reactions
        #   2. Some reactions have no products which is not permissible in KPP
        #   3. Photolysis reactions need 'hv' as a reagent
        rxns = combine_reactions(rxns, combine: '+')
        rxns = rxns.each { |x| add_missing_products(x) }
        rxns = rxns.each { |x| add_photolysis_reagent(x) }
        rxns_out = rxns.map.with_index do |row, i|
          "<#{i + 1}> #{row[:Reaction]} : #{parse_rate_for_kpp(row[:Rate], photo_lookup_table)} ;\n"
        end.join

        # Complex rates need to be both defined and have their rate expression expressed
        complex_defs_out = MCM::Export.wrap_lines(complex_rates.map { |x| x[:Child] },
                                                  starting_char: 'REAL(dp) :: ',
                                                  ending_char: '',
                                                  every_line_end: ' &',
                                                  sep: ', ',
                                                  max_line_length: 78,
                                                  every_line_start: ' ' * 4)
        complex_rates_out = complex_rates.map do |row| # Not using .join("\n") as final line needs line break too
          "#{row[:Child]} = #{parse_rate_for_kpp(row[:Definition], photo_lookup_table)}\n"
        end.join

        # Define the species used in this submechanism
        species_out = species.map { |x| "#{x} = IGNORE ;\n" }.join

        # Peroxy radicals are provided by a proxy RO2 sum
        peroxy_out = MCM::Export.wrap_lines(peroxies.map { |x| "C(ind_#{x})" },
                                            starting_char: '  RO2 = ',
                                            ending_char: '',
                                            every_line_end: ' &',
                                            sep: ' + ',
                                            max_line_length: 78,
                                            every_line_start: ' ' * 6)

        # There's a warning about species in the RO2 sum that don't have a mass
        missing_peroxies_out = MCM::Export.wrap_lines(missing_peroxies,
                                                      starting_char: '    ',
                                                      every_line_start: '    ',
                                                      every_line_end: '',
                                                      ending_char: '',
                                                      max_line_length: 78,
                                                      sep: ' ')

        #---------------------- Write to KPP
        # Citation comes first
        out = citation_out

        # Globals
        out += "#INLINE F90_GLOBAL\n"
        out += complex_defs_out if complex_rates.count.positive?
        out += photo_defs_out if photo_rates.count.positive?
        out += "  REAL(dp) :: zenith\n" if photo_rates.count.positive?
        out += "  REAL(dp) :: M, N2, O2, RO2, H2O\n"
        out += "#ENDINLINE {above lines go into MODULE KPP_ROOT_Global}\n"

        # Species
        out += "#INCLUDE atoms \n"
        out += "#DEFVAR\n"
        # Need to define water if it's used in a rate
        out += "H2O = IGNORE ;\n" if rate_uses_water(rxns, :Rate) || rate_uses_water(complex_rates, :Definition)
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
        out += peroxy_out if peroxies.length.positive?

        # Complex rate coefficients
        out += complex_rates_out if generic && complex_rates.count.positive?
        out += photo_rates_out if photo_rates.count.positive?
        out += "#ENDINLINE \n"
        out += "{above lines go into the SUBROUTINES UPDATE_RCONST and UPDATE_PHOTO}\n"

        # Reactions
        out += "#EQUATIONS\n"
        out += rxns_out

        # Summary
        out + "{ End of Subset. No. of Species = #{species.count}, No. of Reactions = #{rxns.count} }"
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize
      def combine_reactions(rxns, combine: '+')
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

      def add_missing_products(rxn)
        # KPP can't handle reactions with no products
        # This function adds the dummy PROD placeholder for reactions that lack products.
        #
        # Args:
        #   - rxn (Hash): Hash that has :Reaction and :Rate attributes
        #
        # Returns:
        #   A list of hashes where the :Reaction field has been updated if needed.
        rxn[:Reaction] = rxn[:Reaction].gsub(/=\s*$/, '= PROD')
      end

      def add_photolysis_reagent(rxn)
        # Add the 'hv' reagent to photolysis reactions
        # We don't have explicit reaction types, so photolysis are identified
        # by having '<J>' in their rate expression
        #
        # Args:
        #   - rxn (Hash): Hash that has :Reaction and :Rate
        #
        # Returns:
        #   A list of hashes where the :Reaction field has been updated if needed.

        # There's probably a more functional way of doing this...
        rxn[:Reaction] = rxn[:Reaction].gsub('=', '+ hv =') if /J<[0-9]+>/.match?(rxn[:Rate])
      end

      def parse_rate_for_kpp(rate, photolysis_lookup_table)
        # Performs necessary conversions on rates as they are stored in the DB (in FACSIMILE format)
        # to be compatible with KPP.
        #
        # Args:
        #   - rate (string): Input rate in FACSIMILE format.
        #   - photolysis_lookup_table (Hash): Maps MCM J rates to 1-indexed notation for a Fortran array
        #     e.g. {'J<23>'=>'J<1>', 'J<31>'=>'J<2>'}
        #
        # Returns:
        #   - A string containing the rate in KPP format.
        rate = rate.gsub('H2O', 'C(ind_H2O)')

        # Replace photolysis rates with their 1-based index
        rate = rate.gsub(/(J<\d+>)/, photolysis_lookup_table)

        # Replace the D exponent symbol with E
        rate = rate.gsub(/([0-9.+-]+)D([0-9+-]+)/, '\1E\2')

        # Add decimal point to ints
        # This works for everything except 2 edge cases:
        #   - It incorectly decimal points for E-12 -> E-12., which isn't allowed in Fortran
        #   - It adds decimals to photolysis rates (e.g. J<1.>)
        # Rather than get 1 regex that does everything with no errors, these 2 edge cases are separately fixed
        rate = rate.gsub(/(?<![A-Z.\d])(\d+)(?![.])/, '\1.')
        rate = rate.gsub(/(E[-+]?\d+)\./, '\1') # Remove point from exponent
        rate = rate.gsub(/J<(\d+)\.>/, 'J<\1>') # Remove point from photolysis rate

        # Replace disallowed symbols KPP
        rate.gsub(/[<>@]/, '<' => '(', '>' => ')', '@' => '**')
      end

      def rate_uses_water(array, key)
        # Identifies whether a list of objects that contain rates have at least
        # one occurrence of H2O in a rate.
        #
        # Args:
        #   - array (list[Hash]): A list of objects which have entries representing hashes.
        #   - key (symbol): The key containing the object entry with the rate.
        #
        # Returns:
        #   A boolean whether H2O is included in at least 1 rate.
        !array.find { |x| x[key].include? 'H2O' }.nil?
      end

      def form_photolysis_equation(params)
        # Forms a photolysis equation in KPP format using the given photolysis parameters
        # The reason for the 'MCM J = <j>' comment is that the opening J index will get converted to a KPP index
        # later on. The comment won't get changed and thereby provides a reference to where this rate is
        # defined in the MCM.
        #
        # Args:
        #   - params(Hash): A hash with 4 items, representing photolysis parameters:
        #     - J
        #     - l
        #     - m
        #     - n
        #
        # Return:
        #   A string with the photolysis equation in a Fortran-parseable format.
        "J<#{params[:J]}> = #{params[:l]}*(cos(zenith)**#{params[:m]})*exp(-#{params[:n]}*(1/cos(zenith))) " \
          "{MCM J=#{params[:J]}}"
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
