# frozen_string_literal: true

get '/:mechanism/rates/complex' do
  # The root complex rates are stored in a separate table in display order
  parents = DB[:ComplexRatesWeb]
            .select_append(Sequel.lit('row_number() OVER () as parent_order'))
            .join(DB[:Tokens].select(:Token, :NewDatasheet), Token: :Token)
            .from_self(alias: :crw) # Needed else row_number() is applied lazily later on
  # Get all the child tokens by traversing down the tree
  children = MCM::Database.traverse_complex_rates(parents.select_map(:Token))

  # Combine, reorder, and restructure
  @complex_rates = parents
                   .join(children, RootToken: :Token)
                   .order(:parent_order, Sequel.desc(:depth))
                   .to_hash_groups(%i[Token Source NewDatasheet])
  erb :complex
end
