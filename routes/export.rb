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
                  .where(Sequel.lit('tr1.ChildToken IS NULL AND tr2.ParentToken IS NULL'))  # can't get Where to work with fully specified table
                  .select(Sequel[:Tokens][:Token], Sequel[:Tokens][:Definition])
                  .distinct
  complex_rates = tokenized_rates
                  .where(Sequel.lit('tr1.ChildToken IS NOT NULL OR tr2.ParentToken IS NOT NULL'))
                  .select(Sequel[:Tokens][:Token], Sequel[:Tokens][:Definition])
                  .distinct

  # Obtain peroxy information
  peroxies = species
              .where(PeroxyRadical: true)
  missing_peroxies = species
              .where(PeroxyRadical: nil)
  peroxy_out = 'RO2 = ' + peroxies.map(:Name).join(' + ') + " ;\n"
  
  # Make available to download
  content_type 'text/plain'
  attachment 'mcm_export.fac'

  # Format for export
  species_out = species.map(:Name).join(' ')
  rxns_out = all_rxns.map { |row| "% #{row[:Rate]}: #{row[:Reaction]} ;\n" }.join("")
  generic_rates_out = generic_rates.map{ |row| "#{row[:Token]} = #{row[:Definition]} ;\n" }.join("")
  complex_rates_out = complex_rates.map{ |row| "#{row[:Token]} = #{row[:Definition]} ;\n" }.join("")

  # TODO use variable substitution instead of concat
  # TODO need to wrap lines
  out = ""

  # Citation
  citation_file = File.open("#{settings.public_folder}/citation.txt")
  citation_lines = citation_file.readlines.map(&:chomp)
  out += '*' * 77 + " ;\n"
  out += citation_lines.map{ |row| "* #{row}\n" }.join("")
  out += '*' * 77 + " ;\n"

  # Species
  out += '*' * 77 + " ;\n"
  out += "* " + params[:selected].join(" ") + " ;\n*;\n"
  out += "* Variable definitions. All species are listed here.;\n*;\n"
  out += "VARIABLE\n " + species_out + " ;\n"
  out += '*' * 77 + " ;\n"

  # Generic rate coefficients
  if params[:generic]
    out += "*;\n* Generic Rate Coefficients ;\n*;\n"
    out += generic_rates_out
    out += "*;\n* Complex reactions ;\n*;\n"
    out += complex_rates_out
  end

  # Peroxies
  if peroxies.count.positive?
    out += '*' * 77 + " ;\n";
    out += "* Peroxy radicals. ;\n*;\n"
    if missing_peroxies.count.positive?
      out += "* WARNING: The following spceies do not have SMILES strings in the database. ;\n"
      out += "*          If any of these are peroxy radicals the RO2 sum will be wrong!!! ;\n"
      out += '* ' + missing_peroxies.map(:Name).join(' ') + " ;\n"
    end
    out += '*' * 77 + " ;\n"
    out += "* ;\n"
    out += peroxy_out
    out += "*;\n"
  end

  # Reactions
  out += "* Reaction definitions. ;\n*;\n" + rxns_out + "*;\n"

  # Summary
  out += "* End of Subset. No. of Species = #{species.count}, No. of Reactions = #{all_rxns.count} ;"
end
