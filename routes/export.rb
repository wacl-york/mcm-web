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
                .join(:Species, SpeciesID: Sequel[:Products][:SpeciesID])
                .where(Sequel.lit('Reactants.SpeciesID IN ?', stack.to_a))
                .where(SpeciesCategoryID: 1).select(Sequel[:Products][:SpeciesID]).map(:SpeciesID)
                .to_set
    stack = voc_prods.difference(prods)
  end

  # Now find reactions where these species are reactants
  all_rxns = DB[:Reactants]
             .join(:ReactionsWide, [:ReactionID])
             .where(SpeciesID: prods.to_a)
             .select(:Reaction, :Rate)
             .distinct

  # Make available to download
  content_type 'text/plain'
  attachment 'mcm_export.fac'
  all_rxns.map { |row| "#{row[:Rate]}: #{row[:Reaction]}" }.join("\n")
end
