# frozen_string_literal: true

get '/species/:species' do
  @sink_reactions = DB[:Reactants]
                    .where(Species: params[:species])
                    .join(:ReactionsWide, [:ReactionID])
                    .join(:Rates, [:Rate])
                    .order(:Reaction)
                    .select(:Reaction, :Rate, :RateType)

  @precursor_reactions = DB[:Products]
                         .where(Species: params[:species])
                         .join(:ReactionsWide, [:ReactionID])
                         .join(:Rates, [:Rate])
                         .order(:Reaction)
                         .select(:Reaction, :Rate, :RateType)

  @species = DB[:Species]
             .where(Name: params[:species])
             .select(:Name, :Smiles, :Inchi, :Mass)
             .first

  erb :species
end
