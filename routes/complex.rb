# frozen_string_literal: true

get '/?:mechanism?/rates/complex' do
  @mechanism = params[:mechanism] || 'mcm'

  # The starting parents are stored in a separate table
  parents = DB[:ComplexRatesWeb]
            .select(Sequel.lit('Token as TopParent, Token as Child'))
  # Iterate down the tree, finding sub-rates
  complex_tokens = parents
  loop do
    parents = get_children_from_parent(parents, DB)
    break if parents.empty?

    complex_tokens = complex_tokens.union(parents)
  end

  # Child level data: TopParent, Child, Definition, IUPACDefinition
  complex_children = complex_tokens
                     .distinct
                     .join(DB[:Tokens], Token: :Child)
                     .select(:TopParent, :Child, :Definition, :IUPACDefinition)

  # Parent level data: (which complex rates to show and in which order, source, and datasheet)
  complex_parents = DB[:ComplexRatesWeb]
                    .select_append(Sequel.lit('row_number() OVER () as n'))
                    .join(DB[:Tokens].select(:Token, :NewDatasheet), Token: :Token)
                    .from_self(alias: :crw)  # Needed else row_number() is applied lazily later on

  @complex_rates = complex_parents
                   .join(complex_children, TopParent: :Token)
                   .to_hash_groups(%i[Token Source n NewDatasheet])
  erb :complex
end
