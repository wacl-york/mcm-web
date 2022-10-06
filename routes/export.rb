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
             .where(Species: prods.to_a)
             .select(:Reaction, :Rate)
             .distinct

  if params[:inorganic]
    inorg_rxns = DB[:ReactionsWide]
                 .exclude(InorganicCategory: nil)
                 .select(:Reaction, :Rate)
                 .distinct
    all_rxns = all_rxns.union(inorg_rxns)
  end

  # TODO Grab the species involved in these reactions
  # Should already have these... might need to just rejig previous code?

  # TODO extract generic rate if request
  # in the old app code this grabs everything from the generic_rates and complex_rates tables
  # Which I think are what I've got as Tokens. Yeah generic rates are tokens NOT used elsewhere,
  # # complex rates are tokens that ARE used elsewhere
  #
  # TODO Work out which of our species are peroxy radicals
  # The original code uses pybel to search for this pattern
  #_peroxy_smarts = pybel.Smarts('*-O[O;h0;D1]')
  #   m = pybel.readstring('smi', sm.strip())
  #   _peroxy_smarts.findall(m): 
  # BUT IS THIS JUST REGEX? If so can do it direct in DB
  # It should only contain peroxy radicals of species in this dump
  # And just display RO2 = peroxy1 + peroxy2 + ... peroxyn
  
  # TODO FACSIMILIE ORDER:
  # CITATION
  # SUBSPECIES CHOSEN
  # VARIABLE DEFINITION OF ALL SPECIES
  # !! GENERIC RATE COEFFICIENTS (generic_rates in old DB) !!
  # !! COMPLEX RATE COEFFICIENTS (complex_rates in old DB) !!
  # PEROXY RADICALS + warning if have Species without Smiles
  # REACTION DEFINITIONS
  # SUMMARY of number of reactions + species

  # Make available to download
  content_type 'text/plain'
  attachment 'mcm_export.fac'
  all_rxns.map { |row| "#{row[:Rate]}: #{row[:Reaction]}" }.join("\n")

  # ORDER:
  # citation
  # species list of chosen subset
  # VARIABLE then list of all exported species
  # Then 'Generic' and 'Complex' coefficients
end
