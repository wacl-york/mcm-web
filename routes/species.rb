# frozen_string_literal: true

get '/species/:species' do
  # For every species get a list of reactions they are either reactants in (sink)
  # or products in (precursor), along with any relevant metadata
  @sink_rxns = get_reactions(params[:species], column: :Reactants)
  @precursor_rxns = get_reactions(params[:species], column: :Products)
  @species = DB[:Species]
             .where(Name: params[:species])
             .select(:Name, :Smiles, :Inchi, :Mass)
             .first

  erb :species
end

def get_reactions(species, column: :Reactants)
  # Finds all reactions in the DB with a given species
  # and parses into a hierarchical data structure of:
  # [
  #   {
  #     ReactionID: <id>,
  #     Rate: '<rate>',
  #     ReactionCategory: '<category>',
  #     Reactants: [...],
  #     Products: [...]
  #   }
  # ]
  # Find all reactionIDs that this species is involved in
  ids = DB[column].where(Species: species).distinct.select(:ReactionID)

  # Then extract all relevant information
  reactants = DB[:Reactants].where(ReactionID: ids).join(:Species, Name: :Species).to_hash_groups(:ReactionID)
  products = DB[:Products].where(ReactionID: ids).join(:Species, Name: :Species).to_hash_groups(:ReactionID)
  rxns = DB[:Reactions].where(ReactionID: ids).to_hash(:ReactionID)

  # And parse into the desired output format
  # First map needed to turn in Ruby array rather than Sequel Dataset
  # TODO Ideally this would be done as a Sequel Model rather than manually here
  ids.map(:ReactionID).map do |id|
    {
      ReactionID: id,
      Rate: rxns[id][:Rate],
      Category: rxns[id][:ReactionCategory],
      Products: products[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } },
      Reactants: reactants[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } }
    }
  end
end
