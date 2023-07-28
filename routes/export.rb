# frozen_string_literal: true

get '/:mechanism/export' do
  erb :export
end

# rubocop:disable Metrics/BlockLength
post '/:mechanism/export' do
  prods = Set[]
  stack = params[:selected].to_set

  # Find all products from reactions where the user-selected species are reactants
  # and iterate down the reaction tree until reach a non-VOC or run out of reactions
  until stack.empty?
    prods = prods.union(stack)
    # Have to use literal SQL for the WHERE filter as can't seem to get the table name qualifier working, see below
    voc_prods = DB[:Reactants]
                .join(:Reactions, [:ReactionID])
                .join(:Products, [:ReactionID])
                .join(:Species, Name: Sequel[:Products][:Species])
                .where(Sequel.lit('Reactants.Species IN ?', stack.to_a))
                .where(SpeciesCategory: 'VOC',
                       Mechanism: @mechanism).select(Sequel[:Products][:Species]).map(:Species)
                .to_set
    stack = voc_prods.difference(prods)
  end

  # Now find reactions where these species are reactants
  all_rxns = DB[:Reactants]
             .join(:ReactionsWide, [:ReactionID])
             .where(Sequel.lit('Reactants.Species IN ?', prods.to_a))
             .where(Mechanism: @mechanism)
             .select(:ReactionID, :Reaction, :Rate) # Distinct first generates DISTINCT ON - unsupported in SQLite
             .distinct

  # Include all inorganic reactions if user requested
  if params[:inorganic]
    inorg_rxns = DB[:ReactionsWide]
                 .where(Mechanism: @mechanism)
                 .exclude(InorganicCategory: nil)
                 .select(:ReactionID, :Reaction, :Rate)
                 .distinct
    all_rxns = all_rxns.union(inorg_rxns)
  end

  # The export needs to include ALL species involved in this mechanism, not just
  # the user selected ones
  reactants = all_rxns
              .join(Sequel[:Reactants].as(:rea), [:ReactionID])
              .select(Sequel[:rea][:Species].as(:spec))
              .join(:Species, Name: Sequel[:rea][:Species])
              .select(:Name, :PeroxyRadical)
  products = all_rxns
             .join(Sequel[:Products].as(:pro), [:ReactionID])
             .select(Sequel[:pro][:Species].as(:spec))
             .join(:Species, Name: Sequel[:pro][:Species])
             .select(:Name, :PeroxyRadical)

  species = reactants.union(products)

  #------------------- Complex Rates
  # Only find tokenized rates that were used in this sub-mechanism
  used_tokens = all_rxns
                .inner_join(:Rates, [:Rate])
                .inner_join(:TokenizedRates, [:Rate])
                .inner_join(:RateTokens, [:Rate])
                .select_map(:Token)

  # Iteratively find the children of each generation of tokens so they are all
  # fully defined
  all_tokens = [used_tokens.to_set]
  loop do
    used_tokens = get_children_from_parents_set(used_tokens, DB)
    break if used_tokens.empty?

    all_tokens.append(used_tokens.to_set)
  end
  # This line ensures that all rates are defined before they are used in parent
  # rates.
  # Say rate A is defined as a function of rate B, but both A and B are used
  # directly in the sub-mechanism and thus both returned in the first
  # used_tokens assignment. Since this query isn't ordered it could easily
  # return A before B, which would cause the FACSIMILE to fail to build.
  # Reversing the array ensures that all parent rates are located at the end of
  # the array because the tree traversal was top-down, while children can be
  # scattered throughout.
  # The Reduce(Union) restricts multiple copies of a child rate to its first
  # appearance since the Union function is ordered and returns all items of the
  # first input and then any from the second that weren't in the first.
  tokens = all_tokens.reverse.reduce(:union).to_a
  #
  # Get the token definitions. It's a bit ugly to iteratively call the DB, but it's cleaner code
  # than a batch query that returns in order
  complex_rates = tokens.map { |x| { Token: x, Definition: get_token_definition(x, DB) } }

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
  complex_rates_out = complex_rates.map { |row| "#{row[:Token]} = #{row[:Definition]} ;\n" }.join

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
