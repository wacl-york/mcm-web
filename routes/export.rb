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
             .select(:ReactionID, :Reaction, :Rate)  # Can't use distinct as it generates DISTINCT ON - unsupported in SQLite
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
  products = all_rxns
              .join(Sequel[:Products].as(:pro), [:ReactionID])
             .select(Sequel[:pro][:Species].as(:spec))

  species = reactants.union(products).select_map(:spec)

  # Generic rates are those that are not used in any other rate equations, either as a parent or child
  # Complex rates can be used either as a parent or a child
  tokenized_rates = DB[:Tokens]
                    .left_join(Sequel[:TokenRelationships].as(:tr1), ChildToken: Sequel[:Tokens][:Token])
                    .left_join(Sequel[:TokenRelationships].as(:tr2), ParentToken: Sequel[:Tokens][:Token])
  generic_rates = tokenized_rates
                  .where(Sequel.lit('tr1.ChildToken IS NULL AND tr2.ParentToken IS NULL'))  # can't get Where to work with fully specified table
                  .select(Sequel[:Tokens][:Token], Sequel[:Tokens][:Definition])
                  .distinct
  complex_rates = tokenized_rates
                  .where(Sequel.lit('tr1.ChildToken IS NOT NULL OR tr2.ParentToken IS NOT NULL'))
                  .select(Sequel[:Tokens][:Token], Sequel[:Tokens][:Definition])
                  .distinct

  # TODO Work out which of our species are peroxy radicals
  # The original code uses pybel to search for this pattern
  #_peroxy_smarts = pybel.Smarts('*-O[O;h0;D1]')
  #   m = pybel.readstring('smi', sm.strip())
  #   _peroxy_smarts.findall(m): 
  # BUT IS THIS JUST REGEX? If so can do it direct in DB
  # It should only contain peroxy radicals of species in this dump
  # And just display RO2 = peroxy1 + peroxy2 + ... peroxyn
  
  # Make available to download
  content_type 'text/plain'
  attachment 'mcm_export.fac'

  # Format for export
  species_out = species.join(' ')
  rxns_out = all_rxns.map { |row| "% #{row[:Rate]}: #{row[:Reaction]} ;" }.join("\n")
  generic_rates_out = generic_rates.map{ |row| "#{row[:Token]} = #{row[:Definition]} ;" }.join("\n")
  complex_rates_out = complex_rates.map{ |row| "#{row[:Token]} = #{row[:Definition]} ;" }.join("\n")

  # TODO use variable substitution instead of concat
  # TODO need to wrap lines
  out = ""
  # TODO citation
  out += "* " + params[:selected].join(" ") + " ;\n*;\n"
  out += "* Variable definitions. All species are listed here.;\n*;\n"
  out += "VARIABLE\n " + species_out + " ;\n"
  if params[:generic]
    out += "*;\n* Generic Rate Coefficients ;\n*;\n"
    out += generic_rates_out + "\n"
    out += "*;\n* Complex reactions ;\n*;\n"
    out += complex_rates_out + "\n"
  end
  # TODO peroxy warning if have missing smiles
  # TODO peroxy radicals
  out += "* Reaction definitions. ;\n*;\n" + rxns_out + "\n*;\n"
  out += "* End of Subset. No. of Species = #{species.size}, No. of Reactions = #{all_rxns.count} ;"
end
