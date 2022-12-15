# frozen_string_literal: true

get '/export' do
  erb :export
end

post '/export' do
  prods = Set[]
  stack = params[:selected].to_set

  # Firstly find all products until reach inorganic species
  until stack.empty?
    prods = prods.union(stack)
    # Have to use literal SQL for the WHERE filter as can't seem to get the table name qualifier working, see below
    voc_prods = DB[:Reactants]
                .join(:Products, [:ReactionID])
                .join(:Species, Name: Sequel[:Products][:Species])
                .where(Sequel.lit('Reactants.Species IN ?', stack.to_a))
                .where(SpeciesCategory: 'VOC').select(Sequel[:Products][:Species]).map(:Species)
                .to_set
    stack = voc_prods.difference(prods)
  end

  # Now find reactions where these species are reactants
  all_rxns = DB[:Reactants]
             .join(:ReactionsWide, [:ReactionID])
             .where(Sequel.lit('Reactants.Species IN ?', prods.to_a))
             .select(:ReactionID, :Reaction, :Rate) # Distinct first generates DISTINCT ON - unsupported in SQLite
             .distinct

  if params[:inorganic]
    inorg_rxns = DB[:ReactionsWide]
                 .exclude(InorganicCategory: nil)
                 .select(:ReactionID, :Reaction, :Rate)
                 .distinct
    all_rxns = all_rxns.union(inorg_rxns)
  end

  # Grab the species involved in these reactions
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

  # Generic rates are those that are not used in any other rate equations, either as a parent or child
  # Complex rates can be used either as a parent or a child
  tokenized_rates = DB[:Tokens]
                    .left_join(Sequel[:TokenRelationships].as(:tr1), ChildToken: Sequel[:Tokens][:Token])
                    .left_join(Sequel[:TokenRelationships].as(:tr2), ParentToken: Sequel[:Tokens][:Token])
  generic_rates = tokenized_rates
                  .where(Sequel.lit('tr1.ChildToken IS NULL AND tr2.ParentToken IS NULL')) # can't get working in ORM
                  .select(Sequel[:Tokens][:Token], Sequel[:Tokens][:Definition])
                  .distinct
  
  # Complex rates need to be listed in order from leaf nodes up to the top of the tree
  # Since some tokens can be used by multiple parents, need to take care
  all_children = []
  # Start by finding all tokens that are only ever used as children
  new_children = tokenized_rates
                 .where(Sequel.lit('tr1.ChildToken IS NOT NULL AND tr2.ParentToken IS NULL'))
                 .distinct
                 .select_map(Sequel[:tr1][:ChildToken])
  all_children.append(new_children.to_set)
  # Iteratively find the parents of each generation of children
  while true
    new_children = get_parent_from_children(new_children, DB)
    if new_children.empty?
      break
    end

    all_children.append(new_children.to_set)
  end
  # Flatten into a single list of complex tokens, but in reverse order (i.e. starting with parents)
  # and using set union to combine. That way if a token was found in multiple iterations, it is only
  # kept in the latest generation so there is no chance of it being defined before a parent refers to it
  children = all_children.reverse.reduce(:+).to_a.reverse
  # Get the token definitions. It's a bit ugly to iteratively call the DB, but it's cleaner code
  # than a batch query that returns in order
  complex_rates = children.map { |x| { Token: x, Definition: get_token_definition(x, DB) } }

  # Obtain peroxy information
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

  # Format for export
  species_out = wrap_lines(species.map(:Name))
  rxns_out = all_rxns.map { |row| "% #{row[:Rate]} : #{row[:Reaction]} ;\n" }.join
  generic_rates_out = generic_rates.map { |row| "#{row[:Token]} = #{row[:Definition]} ;\n" }.join
  complex_rates_out = complex_rates.map { |row| "#{row[:Token]} = #{row[:Definition]} ;\n" }.join

  out = ''
  spacer = "#{'*' * 77} ;\n"
  empty_comment = "*;\n"

  # Citation
  citation_file = File.open("#{settings.public_folder}/citation.txt")
  citation_lines = citation_file.readlines.map(&:chomp)
  out += spacer
  out += citation_lines.map { |row| "* #{row}\n" }.join
  out += spacer

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

  # Species
  out += spacer
  out += params_out
  out += empty_comment
  out += "* Variable definitions. All species are listed here.;\n"
  out += empty_comment
  out += "VARIABLE\n"
  out += species_out
  out += spacer

  # Generic rate coefficients
  if params[:generic]
    out += empty_comment
    out += "* Generic Rate Coefficients ;\n"
    out += empty_comment
    out += generic_rates_out
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
end
