# frozen_string_literal: true

get '/:mechanism/rates/complex' do
  # The starting parents are stored in a separate table
  parents = DB[:ComplexRatesWeb]
            .select(Sequel.lit('Token as TopParent, Token as Child'))
  # Iterate down the tree, finding sub-rates
  depth = 0
  complex_tokens = parents
                   .select_append(Sequel.lit("#{depth} as depth"))
  loop do
    depth += 1
    parents = get_children_from_parent(parents, DB)
              .select_append(Sequel.lit("#{depth} as depth"))
    break if parents.empty?

    complex_tokens = complex_tokens.union(parents)
  end

  # Child level data: TopParent, Child, Definition
  # For each child token want the lowest depth
  complex_children = complex_tokens
                     .distinct
                     .join(DB[:Tokens], Token: :Child)
                     .group_by(:TopParent, :Child, :Definition)
                     .select(:TopParent, :Child, :Definition, Sequel.lit('max(depth) as Depth'))

  # Parent level data: (which complex rates to show and in which order, source, and datasheet)
  complex_parents = DB[:ComplexRatesWeb]
                    .select_append(Sequel.lit('row_number() OVER () as parent_order'))
                    .join(DB[:Tokens].select(:Token, :NewDatasheet), Token: :Token)
                    .from_self(alias: :crw)  # Needed else row_number() is applied lazily later on

  @complex_rates = complex_parents
                   .join(complex_children, TopParent: :Token)
                   .order(:parent_order, Sequel.desc(:depth))
                   .to_hash_groups(%i[Token Source NewDatasheet])
  erb :complex
end
