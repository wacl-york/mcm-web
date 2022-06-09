# frozen_string_literal: true

get '/species_info/:id' do

  @sink_reactions = DB.fetch("SELECT Reaction, Rate, RateTypes.Name as RateCategory FROM Reactants INNER JOIN ReactionsWide USING(ReactionID) INNER JOIN Reactions USING(ReactionID) INNER JOIN Rates USING(RateID) LEFT JOIN RateTypes USING(RateTypeID) WHERE SpeciesID = ? ORDER BY Reaction;", params[:id])

  @precursor_reactions = DB.fetch("SELECT Reaction, Rate, RateTypes.Name as RateCategory FROM Products INNER JOIN ReactionsWide USING(ReactionID) INNER JOIN Reactions USING(ReactionID) INNER JOIN Rates USING(RateID) LEFT JOIN RateTypes USING(RateTypeID) WHERE SpeciesID = ? ORDER BY Reaction;", params[:id])

  @species = DB.fetch("SELECT Name, Smiles, Inchi, Mass FROM Species WHERE SpeciesID = ?", params[:id]).first

  erb :species_info
end
