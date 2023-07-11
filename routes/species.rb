# frozen_string_literal: true

get '/?:mechanism?/species/:species' do
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM

  # For every species get a list of reactions they are either reactants in (sink)
  # or products in (precursor), along with any relevant metadata
  @sink_rxns = get_reactions(params[:species], column: :Reactants)

  puts "SINK RXNS" 
  puts @sink_rxns

  @precursor_rxns = get_reactions(params[:species], column: :Products)
  @precursor_page_size = 5
  @precursor_num_pages = (@precursor_rxns.size / @precursor_page_size.to_f).ceil
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
  @marklist = cookies[:marklist]
  @marklist = @marklist.nil? ? [] : @marklist.split(',')
  erb :species
end

def get_reactions(species, column: :Reactants)
  # Find reactions that this species is involved in
  ids = DB[column].where(Species: species).distinct.map(:ReactionID)
  j # Parse reaction into a standardised hierarchical structure
  read_reaction(ids)
end
