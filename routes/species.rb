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
  @synonyms = DB[:SpeciesSynonyms]
              .where(Species: params[:species])
              .select_append(Sequel.function(:row_number).over(partition: :Species,
                                                               order: Sequel.desc(:NumReferences)).as(:n))
              .from_self(alias: :m3) # 'where' gets applied at wrong stage without this
              .where { n <= 5 }
              .map(:Synonym).join(', ')
  erb :species
end

def get_reactions(species, column: :Reactants)
  # Find reactions that this species is involved in
  ids = DB[column].where(Species: species).distinct.map(:ReactionID)
  j # Parse reaction into a standardised hierarchical structure
  read_reaction(ids)
end
