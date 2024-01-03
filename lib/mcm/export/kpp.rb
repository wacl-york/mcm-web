# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    # rubocop:disable Metrics/ClassLength
    class KPP
      CONTENT_TYPE = 'text/plain'
      FILE_NAME = 'mcm_export.eqn'
      PHOTOLYSIS_MAPPING = {
        1 => {
          order: 1,
          name: 'O3_O1D',
          reactants: 'O3',
          products: 'O(1D) + O2'
        },
        2 => {
          order: 2,
          name: 'O3_O3P',
          reactants: 'O3',
          products: 'O(3P) + O2'
        },
        3 => {
          order: 3,
          name: 'H2O2',
          reactants: 'H2O2',
          products: 'OH + OH'
        },
        4 => {
          order: 4,
          name: 'NO2',
          reactants: 'NO2',
          products: 'NO + O(3P)'
        },
        5 => {
          order: 5,
          name: 'NO3_NO',
          reactants: 'NO3',
          products: 'NO + O2'
        },
        6 => {
          order: 6,
          name: 'NO3_NO2',
          reactants: 'NO3',
          products: 'NO2 + O(3P)'
        },
        7 => {
          order: 7,
          name: 'HONO',
          reactants: 'HONO',
          products: 'NO + OH'
        },
        8 => {
          order: 8,
          name: 'HNO3',
          reactants: 'HNO3',
          products: 'NO2 + OH'
        },
        11 => {
          order: 9,
          name: 'HCHO_H',
          reactants: 'HCHO',
          products: 'H + HCO'
        },
        12 => {
          order: 10,
          name: 'HCHO_H2',
          reactants: 'HCHO',
          products: 'H2 + CO'
        },
        13 => {
          order: 11,
          name: 'CH3CHO',
          reactants: 'CH3CHO',
          products: 'CH3 + HCO'
        },
        14 => {
          order: 12,
          name: 'C2H5CHO',
          reactants: 'C2H5CHO',
          products: 'C2H5 + HCO'
        },
        15 => {
          order: 13,
          name: 'C3H7CHO_HCO',
          reactants: 'C3H7CHO',
          products: 'n-C3H7 + HCO'
        },
        16 => {
          order: 14,
          name: 'C3H7CHO_C2H4',
          reactants: 'C3H7CHO',
          products: 'C2H4 + CH3CHO'
        },
        17 => {
          order: 15,
          name: 'IPRCHO',
          reactants: 'IPRCHO',
          products: 'n-C4H9 + HCO'
        },
        18 => {
          order: 16,
          name: 'MACR_HCO',
          reactants: 'MACR',
          products: 'CH2=CCH3 + HCO'
        },
        19 => {
          order: 17,
          name: 'MACR_H',
          reactants: 'MACR',
          products: 'CH2=C(CH3)CO + H'
        },
        20 => {
          order: 18,
          name: 'C5HPALD1',
          reactants: 'C5HPALD1',
          products: 'CH3C(CHO)=CHCH2O + OH'
        },
        21 => {
          order: 19,
          name: 'CH3COCH3',
          reactants: 'CH3COCH3',
          products: 'CH3CO + CH3'
        },
        22 => {
          order: 20,
          name: 'MEK',
          reactants: 'MEK',
          products: 'CH3CO + C2H5'
        },
        23 => {
          order: 21,
          name: 'MVK_CO',
          reactants: 'MVK',
          products: 'CH3CH=CH2 + CO'
        },
        24 => {
          order: 22,
          name: 'MVK_C2H3',
          reactants: 'MVK',
          products: 'CH3CO + CH2=CH'
        },
        31 => {
          order: 23,
          name: 'GLYOX_H2',
          reactants: 'GLYOX',
          products: 'CO + CO + H2'
        },
        32 => {
          order: 24,
          name: 'GLYOX_HCHO',
          reactants: 'GLYOX',
          products: 'HCHO + CO'
        },
        33 => {
          order: 25,
          name: 'GLYOX_HCO',
          reactants: 'GLYOX',
          products: 'HCO + HCO'
        },
        34 => {
          order: 26,
          name: 'MGLYOX',
          reactants: 'MGLYOX',
          products: 'CH3CO + HCO'
        },
        35 => {
          order: 27,
          name: 'BIACET',
          reactants: 'BIACET',
          products: 'CH3CO + CH3CO'
        },
        41 => {
          order: 28,
          name: 'CH3OOH',
          reactants: 'CH3OOH',
          products: 'CH3O + OH'
        },
        51 => {
          order: 29,
          name: 'CH3NO3',
          reactants: 'CH3NO3',
          products: 'CH3O + NO2'
        },
        52 => {
          order: 30,
          name: 'C2H5NO3',
          reactants: 'C2H5NO3',
          products: 'C2H5O + NO2'
        },
        53 => {
          order: 31,
          name: 'NC3H7NO3',
          reactants: 'NC3H7NO3',
          products: 'n-C3H7O + NO2'
        },
        54 => {
          order: 32,
          name: 'IC3H7NO3',
          reactants: 'IC3H7NO3',
          products: 'CH3C(O.)CH3 + NO2'
        },
        55 => {
          order: 33,
          name: 'TC4H9NO3',
          reactants: 'TC4H9NO3',
          products: 't-C4H9O + NO2'
        },
        56 => {
          order: 34,
          name: 'NOA',
          reactants: 'NOA',
          products: 'CH3C(O)CH2(O.) + NO2 or CH3CO + HCHO + NO2'
        }
      }.freeze

      # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/UnusedMethodArgument

      def export(species, rxns, complex_rates, photo_rates, _root_species, missing_peroxies, peroxies, citation,
                 generic)
        #---------------------- Setup
        # Citation
        citation_fmt = citation.map { |row| "// #{row}" }.join("\n")
        citation_out = "// #{'*' * 56} ;\n#{citation_fmt}\n// #{'*' * 56} ;\n"

        # Reactions need several conversions to be usable in KPP
        #   1. Combine identical reactions
        #   2. Some reactions have no products which is not permissible in KPP
        #   3. Photolysis reactions need 'hv' as a reagent
        photo_lookup_table = {}
        photo_rates.each { |x| photo_lookup_table["J<#{x[:J]}>"] = "J(J_#{PHOTOLYSIS_MAPPING[x[:J]][:name]})" }

        rxns = combine_reactions(rxns, combine: '+')
        rxns = rxns.each { |x| add_missing_products(x) }
        rxns = rxns.each { |x| add_photolysis_reagent(x) }
        rxns_out = rxns.map.with_index do |row, i|
          "<#{i + 1}> #{row[:Reaction]} : #{parse_rate_for_kpp(row[:Rate], photo_lookup_table)} ;\n"
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
        # TODO should this include inorganics?
        missing_peroxies_species = MCM::Export.wrap_lines(missing_peroxies,
                                                          starting_char: '  ! ',
                                                          every_line_start: '  ! ',
                                                          every_line_end: '',
                                                          ending_char: '',
                                                          max_line_length: 78,
                                                          sep: ' ')
        missing_peroxies_out = "  ! WARNING: The following species do not have SMILES strings in the database. \n"
        missing_peroxies_out += "  !#{' ' * 11}If any of these are peroxy radicals the RO2 sum will be wrong! \n"
        missing_peroxies_out += missing_peroxies_species

        #---------------------- Write to KPP
        # Citation comes first
        out = citation_out
        out += "\n"

        # Species
        out += "#INCLUDE atoms \n\n"
        out += "#DEFVAR\n"
        # Need to define water if it's used in a rate
        out += "H2O = IGNORE ;\n" if rate_uses_water(rxns, :Rate) || rate_uses_water(complex_rates, :Definition)
        out += species_out
        out += "\n"

        # Load variables from constants file
        out += "#INLINE F90_RCONST \n"
        out += "  USE constants_mcm\n"
        out += "  ! Peroxy radicals\n"
        out += missing_peroxies_out if missing_peroxies.length.positive?
        out += peroxy_out if peroxies.length.positive?
        out += "  CALL define_constants_mcm\n"
        out += '#ENDINLINE '
        out += "{above lines go into the SUBROUTINES UPDATE_RCONST and UPDATE_PHOTO}\n"
        out += "\n"

        # Reactions
        out += "#EQUATIONS\n"
        out += rxns_out

        # Summary
        out + "// End of Subset. No. of Species = #{species.count}, No. of Reactions = #{rxns.count}"
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/UnusedMethodArgument

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
        # This function adds the dummy PROD placeholder for reactions that lack products
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
        # Replace photolysis rates with their 1-based index
        rate = rate.gsub(/(J<\d+>)/, photolysis_lookup_table)

        # Replace the D exponent symbol with E
        rate = rate.gsub(/([0-9.+-]+)D([0-9+-]+)/, '\1E\2')

        # Add decimal point to ints
        # This works for everything except 2 edge cases:
        #   - It incorectly decimal points for E-12 -> E-12., which isn't allowed in Fortran
        #   - It adds decimals to photolysis rates (e.g. J<1.>)
        # Rather than get 1 regex that does everything with no errors, these 2 edge cases are separately fixed
        rate = rate.gsub(/(?<![A-Z.\d])(\d+)(?![.\d])/, '\1.')
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

      def form_photolysis_equation(params, name)
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
        #   - name (String): The name of this rate
        #
        # Return:
        #   A string with the photolysis equation in a Fortran-parseable format.
        lhs = "J(J_#{name}) ".ljust(18, ' ')
        rhs = "#{params[:l]}*(cos(zenith)**#{params[:m]})*exp(-#{params[:n]}*(1/cos(zenith)))".ljust(61, ' ')
        "#{lhs} = #{rhs} ! MCM J=#{params[:J]}"
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def constants_file(mechanism)
        # Retrieve all tokenized rates in mechanism
        # get tokenized rates in order
        all_reactions = DB[:reactions]
                        .where(Mechanism: mechanism)
        parent_tokens = MCM::Database.get_rate_tokens_used_in_submechanism(all_reactions)
        complex_rates = MCM::Database.traverse_complex_rates(parent_tokens)
        puts "complex rates: #{complex_rates.all}"

        #------------------- Photolysis Rates
        # Photolysis rates need to be both defined and have their equation generated from the raw parameters and parsed
        # Create a lookup table mapping the MCM J number into its 1-based index for use in a Fortran array
        photo_rates = MCM::Database.all_photolysis_rates
        photo_lookup_table = {}
        photo_rates.each { |x| photo_lookup_table["J<#{x[:J]}>"] = PHOTOLYSIS_MAPPING[x[:J]][:name] }
        photo_indices_out = PHOTOLYSIS_MAPPING.map do |k, v|
          name = v[:name].ljust(15, ' ')
          ord = v[:order].to_s.rjust(2, ' ')
          mcm_j = k.to_s.rjust(2, ' ')
          reactants = v[:reactants].ljust(9, ' ')
          products = v[:products]
          "  INTEGER, PARAMETER :: J_#{name} = #{ord} ! MCM J=#{mcm_j} #{reactants} -> #{products}"
        end

        # Generate the definition and parsed rate equations
        photo_defs_out = "  REAL(dp), DIMENSION(#{photo_rates.count}) :: J\n"
        photo_rates_out = photo_rates.map do |row| # Not using .join("\n") as final line needs line break too
          rate = form_photolysis_equation(row, PHOTOLYSIS_MAPPING[row[:J]][:name])
          rate_parsed = parse_rate_for_kpp(rate, photo_lookup_table)
          "    #{rate_parsed}\n"
        end.join

        # Complex rates need to be both defined and have their rate expression expressed
        complex_defs_out = MCM::Export.wrap_lines(complex_rates.map { |x| x[:Child] },
                                                  starting_char: '  REAL(dp) :: ',
                                                  ending_char: '',
                                                  every_line_end: ' &',
                                                  sep: ', ',
                                                  max_line_length: 78,
                                                  every_line_start: ' ' * 6)
        complex_rates_out = complex_rates.map do |row| # Ditto .join("\n") comment as photo_rates_out
          "    #{row[:Child]} = #{parse_rate_for_kpp(row[:Definition], photo_lookup_table)}\n"
        end.join

        # Header
        out = "! rate constants and functions for the MCM-generated KPP equation file\n"
        out += "\n"
        out += "MODULE constants_mcm\n"
        out += "\n"
        out += "  USE mcm_Precision, ONLY: dp\n"
        out += "  USE mcm_Parameters ! ind_*\n"
        out += "  USE mcm_Global, ONLY: C, TEMP\n"
        out += "  IMPLICIT NONE\n"
        out += "\n"

        # Definitions
        out += "#{photo_indices_out.join("\n")}\n"
        out += complex_defs_out
        out += photo_defs_out
        out += "  REAL(dp) :: M, N2, O2, RO2, H2O, zenith\n"
        out += "\n"
        out += "  PUBLIC\n"
        out += "\n"

        # CONTAINS
        out += "CONTAINS\n"
        out += "\n"
        out += "  SUBROUTINE define_constants_mcm()\n"
        out += "\n"
        out += complex_rates_out
        out += "\n"
        out += photo_rates_out
        out += "\n"
        out += "  END SUBROUTINE define_constants_mcm\n"
        out += "\n"
        out += "\n"
        out += "END MODULE constants_mcm\n"
        out
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
    # rubocop:enable Metrics/ClassLength
  end
end
