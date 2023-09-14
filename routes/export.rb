# frozen_string_literal: true

get '/:mechanism/export' do
  erb :export
end

# rubocop:disable Metrics/BlockLength
post '/:mechanism/export' do
  # Traverse submechanism to obtain species involved and the reactions
  submech_species = traverse_submechanism(params[:selected], @mechanism)
  submech_rxns = get_reactions_from_species(submech_species, @mechanism)

  # Include all inorganic reactions and species if user requested
  if params[:inorganic]
    inorg_submech = extract_inorganic_submechanism
    # Can safely do a union all as we explicitly didn't include inorganic rxns in the initial submechanism extract
    submech_rxns = inorg_submech[:rxns].union(submech_rxns, all: true)
    submech_species = inorg_submech[:species].union(submech_species)
  end

  # Get Peroxy information
  submech_species = submech_species
                    .join(:Species, Name: :Species)
                    .select(:Name, :PeroxyRadical)

  #------------------- Complex Rates
  # Only find tokenized rates that were used in this sub-mechanism
  used_tokens = submech_rxns
                .inner_join(:Rates, [:Rate])
                .inner_join(:TokenizedRates, [:Rate])
                .inner_join(:RateTokens, [:Rate])
                .select_map(:Token)
  complex_rates = traverse_complex_rates(used_tokens)

  #------------------- Peroxy radicals
  peroxies = submech_species
             .where(PeroxyRadical: true)
  missing_peroxies = submech_species
                     .where(PeroxyRadical: nil)

  export_func = exporter_factory(params[:format])
  export_func.call(
    submech_species.select_map(:Name),
    submech_rxns.all,
    complex_rates.all,
    params[:selected],
    missing_peroxies.select_map(:Name),
    peroxies.select_map(:Name),
    generic: params[:generic]
  )
end
# rubocop:enable Metrics/BlockLength

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def traverse_submechanism(root_species, mechanism)
  # Traverses a sub-mechanism from a collection of starting species down to sink species
  #
  # This is a breadth-first search despite not explicitly ordering as such by using a depth counter (3.4 https://www.sqlite.org/lang_with.html)
  # For some unknown reason, adding a depth counter causes an infinite loop and runs out of memory
  #
  # Args:
  #   - root_species: Array of strings with the starting Species names
  #   - mechanism: String with the mechanism name to traverse.
  #
  # Returns:
  #   - A Sequel dataset with 2 column
  #     - Species: Any species that are involved in this submechanism, ordered breadth first.
  DB[:get_submechanism]
    .with_recursive(
      :get_submechanism,
      DB[:Species] # Assures that the user selected species exist in the DB
        .where(Name: root_species)
        .select(:Name),
      DB[:get_submechanism]
        .join(:Reactants, Species: Sequel[:get_submechanism][:Species])
        .join(:Products, [:ReactionID])
        .join(:Reactions, [:ReactionID])
        .join(:Species, Name: Sequel[:Reactants][:Species])
        .where(Mechanism: mechanism, SpeciesCategory: 'VOC')
        .select(Sequel[:Products][:Species]),
      args: [:Species],
      union_all: false
    )
    .from_self(alias: :sub)
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

def get_reactions_from_species(species, mechanism)
  # Retrieves reaction information from species that are reactants, preserving the order that the species were in.
  #
  # Args:
  #   - Species: Sequel dataset with 1 column, Species
  #
  # Returns:
  #   - Sequel dataset with 3 columns: ReactionID, Reaction, Rate
  species
    .select_append(Sequel.lit('row_number() over() AS i'))
    .from_self(alias: :ord) # Needed to ensure row_number applied at correct time
    .join(:Reactants, [:Species])
    .join(:Species, Name: Sequel[:Reactants][:Species])
    .join(:ReactionsWide, [:ReactionID])
    .where(SpeciesCategory: 'VOC', Mechanism: mechanism)
    .order_by(:i)
    .select(Sequel[:ReactionsWide][:ReactionID], :Reaction, :Rate)
    .from_self(alias: :rea)
end

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/ParameterLists
# rubocop:disable Metrics/MethodLength
def export_facsimile(species, rxns, rates, root_species, missing_peroxies, peroxies, generic: false)
  # Make available to download
  content_type 'text/plain'
  filename = 'mcm_export.fac'
  attachment filename

  # Format sections for export
  species_out = wrap_lines(species)
  rxns_out = rxns.map { |row| "% #{row[:Rate]} : #{row[:Reaction]} ;\n" }.join
  complex_rates_out = rates.map { |row| "#{row[:Child]} = #{row[:Definition]} ;\n" }.join
  params_out = wrap_lines(root_species,
                          starting_char: '* ',
                          every_line_start: '* ',
                          every_line_end: ' ;',
                          ending_char: ' ;',
                          sep: ' ')
  missing_peroxies_out = wrap_lines(missing_peroxies,
                                    starting_char: '* ',
                                    every_line_start: '* ',
                                    every_line_end: ' ;',
                                    ending_char: ' ;',
                                    sep: ' ')
  peroxy_out = wrap_lines(peroxies,
                          starting_char: 'RO2 = ',
                          ending_char: ';',
                          sep: ' + ',
                          max_line_length: 65,
                          every_line_start: ' ' * 6)

  spacer = "#{'*' * 77} ;\n"
  empty_comment = "*;\n"

  citation_file = File.open("#{settings.public_folder}/citation.txt")
  citation_lines = citation_file.readlines.map(&:chomp)

  #---------------------- Write Facsimile file
  # Citation comes first
  out = ''
  out += spacer
  out += citation_lines.map { |row| "* #{row}\n" }.join
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
  if peroxies.count.positive?
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
  end

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
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Metrics/MethodLength

# rubocop:disable Metrics/MethodLength
def extract_inorganic_submechanism
  # Extracts inorganic reactions and the species involved within
  #
  # Args:
  #   - None
  #
  # Returns:
  #   - An object with attributes:
  #     - rxns: Sequel Dataset with ReactionID, Reaction, Rate columns
  #     - species: Sequel Dataset with Species column
  rxns = DB[:ReactionsWide]
         .exclude(InorganicCategory: nil)
         .select(:ReactionID, :Reaction, :Rate)
         .from_self(alias: :inorg)

  reactants = rxns
              .join(:Reactants, [:ReactionID])
              .select(:Species)
  products = rxns
             .join(:Products, [:ReactionID])
             .select(:Species)
  species = reactants.union(products)
  { species: species, rxns: rxns }
end
# rubocop:enable Metrics/MethodLength

def export_default(*)
  'Unknown format'
end

def exporter_factory(format)
  # Returns the selected export format
  #
  # Args:
  #   - format: String representing which format to use
  #
  # Returns:
  #   A function that can export the mechanism
  case format
  when 'facsimile'
    method(:export_facsimile)
  else
    puts "Unknown export format '#{format}'"
    method(:export_default)
  end
end
