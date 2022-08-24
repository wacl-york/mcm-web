# frozen_string_literal: true

get '/species_info/:id' do
  @sink_reactions = DB[:Reactants]
                    .join(:ReactionsWide, [:ReactionID])
                    .join(:Reactions, [:ReactionID])
                    .join(:Rates, [:RateID])
                    .left_join(:RateTypes, [:RateTypeID])
                    .where(SpeciesID: params[:id])
                    .order(:Reaction)
                    .select(:Reaction, :Rate, Sequel.as(Sequel[:RateTypes][:Name], :RateCategory))

  @precursor_reactions = DB[:Products]
                         .join(:ReactionsWide, [:ReactionID])
                         .join(:Reactions, [:ReactionID])
                         .join(:Rates, [:RateID])
                         .left_join(:RateTypes, [:RateTypeID])
                         .where(SpeciesID: params[:id])
                         .order(:Reaction)
                         .select(:Reaction, :Rate, Sequel.as(Sequel[:RateTypes][:Name], :RateCategory))

  @species = DB[:Species]
             .where(SpeciesID: params[:id])
             .select(:Name, :Smiles, :Inchi, :Mass)
             .first

  erb :species_info
end
