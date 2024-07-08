# frozen_string_literal: true

get '/:mechanism/species/:species' do
  # For every species get a list of reactions they are either reactants in (sink)
  # or products in (precursor), along with any relevant metadata
  @sink_rxns = get_reactions(params[:species], @mechanism, column: :Reactants)
  @precursor_rxns = get_reactions(params[:species], @mechanism, column: :Products)
  @precursor_page_size = 5
  @precursor_num_pages = (@precursor_rxns.size / @precursor_page_size.to_f).ceil
  species_query = DB[:Species]
                  .where(Name: params[:species])
                  .select(:Name, :Smiles, :Inchi, :Mass)
  @species = species_query.first
  @synonyms = MCM::Database.get_top_5_synonyms(species_query)
                           .map(:Synonym).join('; ')
  @marklist = cookies[:marklist]
  @marklist = @marklist.nil? ? [] : @marklist.split(',')
  @title = "#{params[:mechanism]} - #{params[:species]}"
  erb :species
end

def get_reactions(species, mechanism, column: :Reactants)
  # Find reactions that this species is involved in
  ids = DB[column]
        .join(DB[:Reactions].as(:rxns), [:ReactionID])
        .where(Species: species, Mechanism: mechanism)
        .select(Sequel[:rxns][:ReactionID])
        .distinct
        .map(:ReactionID)
  # Parse reaction into a standardised hierarchical structure
  MCM::Database.get_reaction(ids)
end
