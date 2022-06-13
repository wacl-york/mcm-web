# frozen_string_literal: true

get '/export' do
  erb :export
end

post '/export' do
  prods = []
  all_rxns = []
  stack = DB[:Species].where(Name: params[:selected]).map(:SpeciesID)

  # Firstly find all products
  until stack.empty?
      species = stack.pop()
      prods.push(species)
      # Couldn't get this working with the ORM, and found more readable in SQL thanks to aliasing tables
      voc_prods = DB["SELECT Products.SpeciesID FROM Reactants INNER JOIN Products USING(ReactionID) INNER JOIN Species prods ON prods.SpeciesID = Products.SpeciesID WHERE Reactants.SpeciesID = ? AND prods.SpeciesCategoryID = 1", species].distinct.map(:SpeciesID)
      voc_prods.each do |prod|
        if !(stack.include? prod) && !(prods.include? prod)
              stack.push(prod)
          end
      end
  end

  # Now find unique reactions
  all_rxns = DB[:Reactants].join(:ReactionsWide, [:ReactionID]).where(SpeciesID: prods).select(:Reaction, :Rate).distinct

  # Make available to download
  content_type 'text/plain'
  attachment "mcm_export.fac"
  all_rxns.map { |row| "#{row[:Rate]}: #{row[:Reaction]}" }.join("\n")
end
