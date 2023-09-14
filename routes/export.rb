# frozen_string_literal: true

get '/:mechanism/export' do
  erb :export
end

# rubocop:disable Metrics/BlockLength
post '/:mechanism/export' do
  submechanism = traverse_submechanism(params[:selected], @mechanism)

  # Include all inorganic reactions if user requested
  if params[:inorganic]
    inorganic_rxns = DB[:Reactions].exclude(InorganicReactionCategory: nil).select(:ReactionID)
    submechanism = inorganic_rxns.union(submechanism)
  end

  # Get full reaction info
  all_rxns = submechanism
             .join(DB[:ReactionsWide], [:ReactionID])
             .select(:ReactionID, :Reaction, :Rate)

  # Get all species involved inthis submechanism
  species = get_species_from_reactions(submechanism)
            .join(:Species, Name: :Species)
            .select(:Name, :PeroxyRadical)

  #------------------- Complex Rates
  # Only find tokenized rates that were used in this sub-mechanism
  used_tokens = all_rxns
                .inner_join(:Rates, [:Rate])
                .inner_join(:TokenizedRates, [:Rate])
                .inner_join(:RateTokens, [:Rate])
                .select_map(:Token)
  complex_rates = traverse_complex_rates(used_tokens)

  #------------------- Peroxy radicals
  peroxies = species
             .where(PeroxyRadical: true)
  missing_peroxies = species
                     .where(PeroxyRadical: nil)
  peroxy_out = wrap_lines(peroxies.map(:Name),
                          starting_char: 'RO2 = ',
                          ending_char: ';',
                          sep: ' + ',
                          max_line_length: 65,
                          every_line_start: ' ' * 6)

  # Make available to download
  content_type 'text/plain'
  attachment 'mcm_export.fac'

  # Format sections for export
  species_out = wrap_lines(species.map(:Name))
  rxns_out = all_rxns.map { |row| "% #{row[:Rate]} : #{row[:Reaction]} ;\n" }.join
  complex_rates_out = complex_rates.map { |row| "#{row[:Child]} = #{row[:Definition]} ;\n" }.join

  params_out = wrap_lines(params[:selected],
                          starting_char: '* ',
                          every_line_start: '* ',
                          every_line_end: ' ;',
                          ending_char: ' ;',
                          sep: ' ')

  missing_peroxies_out = wrap_lines(missing_peroxies.map(:Name),
                                    starting_char: '* ',
                                    every_line_start: '* ',
                                    every_line_end: ' ;',
                                    ending_char: ' ;',
                                    sep: ' ')

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
  if params[:generic]
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
  out + "* End of Subset. No. of Species = #{species.count}, No. of Reactions = #{all_rxns.count} ;"
  #---------------------- End write facsimile file
end
# rubocop:enable Metrics/BlockLength

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def traverse_submechanism(root_species, mechanism)
  # Traverses a sub-mechanism from a collection of starting species down to sink species
  #
  # TODO: Get breadth first search working. Say export CH4, the 2 CH4 reactions won't be consecutive
  #
  # Args:
  #   - root_species: Array of strings with the starting Species names
  #   - mechanism: String with the mechanism name to traverse.
  #
  # Returns:
  #   - A Sequel dataset with 1 column
  #     - ReactionId: A set of ReactionIDs, ordered by first appearance in the submechanism
  DB[:get_submechanism]
    .with_recursive(
      :get_submechanism,
      DB[:Reactants]
      .join(:Species, Name: :Species)
      .join(:Reactions, [:ReactionID])
      .where(Mechanism: mechanism, SpeciesCategory: 'VOC', Species: root_species)
      .select(:ReactionID),
      DB[:get_submechanism]
        .join(:Products, ReactionID: Sequel[:get_submechanism][:ReactionID])
        .join(:Reactants, Species: Sequel[:Products][:Species])
        .join(:Reactions, ReactionID: Sequel[:Reactants][:ReactionID])
        .join(:Species, Name: Sequel[:Reactants][:Species])
        .where(Mechanism: mechanism, SpeciesCategory: 'VOC')
        .select(Sequel[:Reactants][:ReactionID]),
      args: [:ReactionID],
      union_all: false
    )
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

def get_species_from_reactions(ids)
  # Finds unique species involved in given reactions
  #
  # Args:
  #   - ids: Sequel dataset with the column ReactionID.
  #
  # Returns:
  #   - A Sequel dataset with the column Species
  reactants = ids
              .join(DB[:Reactants], [:ReactionID])
              .select(:Species)
  products = ids
             .join(DB[:products], [:ReactionID])
             .select(:Species)
  reactants.union(products)
end
