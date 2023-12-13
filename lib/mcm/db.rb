# frozen_string_literal: true

module MCM
  # Utility functions for extracting values from the DB
  # rubocop:disable Metrics/ModuleLength
  module Database
    module_function

    def get_submechanism(root_species, include_inorganic, mechanism)
      # Extract a submechanism from a full mechanism starting from specific root species
      #
      # Args:
      #   - root_species (list[string]): List of root species names
      #   - include_inorganic (boolean): Whether to include inorganic reactions
      #   - mechanism (string): The mechanism to search in
      #
      # Returns:
      #   - Sequel dataset with 1 row per reaction and 3 columns: ReactionID, Reaction, Rate
      rxns = traverse_submechanism(root_species, mechanism)
      if include_inorganic
        inorg_rxns = extract_inorganic_submechanism(mechanism)
        rxns = inorg_rxns.union(rxns)
      end
      rxns.join(:ReactionsWide, [:ReactionID]).select(:ReactionID, :Reaction, :Rate)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def traverse_submechanism(root_species, mechanism)
      # Traverses a sub-mechanism from a collection of starting species down to sink species
      #
      # This is a breadth-first search despite not explicitly ordering as such by using a depth counter (3.4 https://www.sqlite.org/lang_with.html)
      # For some unknown reason, adding a depth counter causes an infinite loop and runs out of memory
      #
      # Args:
      #   - root_species: Array of strings with the starting Species names
      #   - mechanism: String with the mechanism name to traverse.
      #
      # Returns:
      #   - A Sequel dataset with 1 row per reaction and 1 column
      #     - ReactionID: The ID of any reactions that are involved in this submechanism, ordered breadth first.
      DB[:submechanism]
        .with_recursive(
          :submechanism,
          DB[:Reactants]
            .join(:Species, Name: Sequel[:Reactants][:Species])
            .join(:Reactions, [:ReactionID])
            .where(Name: root_species, Mechanism: mechanism, SpeciesCategory: 'VOC') # Guard inputs are valid VOC
            .select(Sequel[:Reactions][:ReactionID]),
          DB[:submechanism]
            .join(Sequel[:Products].as(:prds), ReactionID: Sequel[:submechanism][:ReactionID])
            .join(Sequel[:Reactants].as(:rcnts), Species: Sequel[:prds][:Species])
            .join(Sequel[:Species].as(:spec), Name: Sequel[:rcnts][:Species])
            .join(Sequel[:Reactions].as(:rxns2), ReactionID: Sequel[:rcnts][:ReactionID])
            .where(Mechanism: mechanism, SpeciesCategory: 'VOC')
            .select(Sequel[:rxns2][:ReactionID]),
          args: [:ReactionID],
          union_all: false
        )
        .from_self(alias: :sub)
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def get_species_involved_in_reactions(reactions)
      # Returns the species that are involved in the specified reactions, either as products or reactants.
      # Species are returned in the order they first appear in the input reactions
      #
      # Args:
      #   - reactions (Sequel.Dataset): A Dataset with one row per Reaction and columns:
      #     - ReactionID (needed)
      #     - Reaction (unused)
      #     - Rate (unused)
      #
      # Returns:
      #   - A Sequel dataset with one row per species involved in the reactions with 2 columns:
      #     - Name
      #     - PeroxyRadical
      reactions_ord = reactions
                      .select_append(Sequel.lit('row_number() over() AS i'))
                      .from_self(alias: :ord) # Needed to ensure row_number applied at correct time

      reacts = reactions_ord
               .join(DB[:Reactants], [:ReactionID])
               .from_self(alias: :rcts)

      prods = reactions_ord
              .join(DB[:Products], [:ReactionID])
              .from_self(alias: :prds)

      reacts
        .union(prods)
        .join(:Species, Name: :Species)
        .group_by(:Name, :PeroxyRadical)
        .select_append(Sequel.lit('min(i) as rank'))
        .order(:i)
        .from_self(alias: :results)
        .select(:Name, :PeroxyRadical)
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def extract_inorganic_submechanism(mechanism)
      # Extracts inorganic reactions and the species involved within
      #
      # Args:
      #   - mechanism: Mechanism name as string.
      #
      # Returns:
      #   - An object with attributes:
      #     - rxns: Sequel Dataset with ReactionID, Reaction, Rate columns
      #     - species: Sequel Dataset with Species column
      DB[:Reactions]
        .where(Mechanism: mechanism)
        .exclude(InorganicReactionCategory: nil)
        .select(:ReactionID)
        .from_self(alias: :inorg)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def traverse_complex_rates(parents)
      # Traverses complex tokenized rates from parents (i.e. KMT04) down to children.
      # Returns in order firstly by parent, and then by child depth
      # (highest depth first, i.e. FCC, KCO, KCI, KRC, NC, FC, KFPAN)
      # This is a breadth-first traversal, finding all root tokens, then all tokens at the next level down, etc...
      #
      # Args:
      #   - parents: Array of strings with Token names to use as initial parents
      #
      # Returns:
      #   - A dataset with 4 columns and 1 row per child token.
      #     - RootToken: The root parent token
      #     - Child: The child's token name
      #     - Definition: The child's rate definition
      #     - Depth: How many branches down the tree from the root parent was this child
      depth = 0
      new_children = DB[:Tokens]
                     .where(Token: parents)
                     .select(Sequel.lit("Token as RootToken, Token as Child, #{depth} as depth"))
      all_tokens = new_children
      # TODO: change to while loop with new children being empty
      loop do
        depth += 1
        new_children = get_children_token_from_parent_token(new_children, DB)
                       .select_append(Sequel.lit("#{depth} as depth"))
        break if new_children.empty?

        all_tokens = all_tokens.union(new_children)
      end

      # Get each child's rate Definition and limit each child to highest depth
      # In SQLite when using Max or Min in a grouped select, it only returns the corresponding row with the max or min
      # So no need to add a WHERE clause. Madness.
      all_tokens = all_tokens
                   .distinct
                   .join(DB[:Tokens], Token: :Child)
                   .group_by(:RootToken, :Child, :Definition)
                   .select_append(Sequel.lit('max(depth) as Depth'))
                   .from_self(alias: :all)

      # Identify which root tokens are simple or complex for later ordering
      simple_generic_order = all_tokens
                             .group_and_count(:RootToken)
                             .from_self(alias: :sim)
                             .select_append(Sequel.lit('count > 1 as IsComplex'))

      # Want to order by 3 conditions:
      #   - Whether simple or complex (simple has a tree with depth=1)
      #   - By root parent token
      #   - By depth of child token
      all_tokens
        .join(simple_generic_order, RootToken: :RootToken)
        .order(:IsComplex, :RootToken, Sequel.desc(:depth))
        .from_self(alias: :out)
        .select(:RootToken, :Child, :Definition, :depth)
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def get_rate_tokens_used_in_submechanism(submechanism)
      # Returns the tokenized rates used in a submechanism
      #
      #  Args:
      #    - submechanism (Sequel.Dataset): Dataset where every row corresponds to a reaction.
      #      Must have at least a 'rate' column
      #
      #  Returns:
      #    A Sequel.Dataset with 1 column: Token
      submechanism
        .inner_join(:Rates, [:Rate])
        .inner_join(:TokenizedRates, [:Rate])
        .inner_join(:RateTokens, [:Rate])
        .select_map(:Token)
    end

    def get_children_token_from_parent_token(parents, _db)
      DB[:TokenRelationships]
        .join(parents, Child: :ParentToken)
        .select(Sequel.lit('RootToken, ChildToken as Child'))
    end

    def all_photolysis_rates
      # Retrieves all photolysis rates used in the mechanim
      #
      # Args:
      #   - None
      # Returns:
      #   A Sequel Dataset of photolysis parameters with columns:
      #     - J
      #     - l
      #     - m
      #     - n
      DB[:PhotolysisParameters]
        .exclude(l: nil)
        .order(:J)
    end

    def get_photolysis_rates_used_in_submechanism(submechanism)
      # Returns the photolysis rates used in a submechanism
      #
      #  Args:
      #    - submechanism (Sequel.Dataset): Dataset where every row corresponds to a reaction.
      #      Must have at least a 'rate' column
      #
      #  Returns:
      #    A Sequel.Dataset with 4 columns: J, l, m, n
      submechanism
        .inner_join(:Rates, [:Rate])
        .inner_join(:PhotolysisRates, [:Rate])
        .inner_join(:PhotolysisParameters, [:J])
        .select(Sequel[:PhotolysisParameters][:J], :l, :m, :n)
        .from_self(alias: :photo2)
        .distinct
        .order(Sequel[:photo2][:J])
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def get_reaction(reaction_ids)
      # Parses given reactions from the DB into a hierarchical data structure
      # Ideally this would be done as a Sequel Model rather than manually here
      #
      # Args:
      #   - reaction_ids ([Int]): Array of integers
      #
      # Returns:
      # A list of reactions in the following format:
      #   [
      #     {
      #       ReactionID: <id>,
      #       Rate: '<rate>',
      #       ReactionCategory: '<category>',
      #       Reactants: [...],
      #       Products: [...]
      #     }
      #   ]

      # Extract the constituent parts of a reaction
      reactants = DB[:Reactions]
                  .where(ReactionID: reaction_ids)
                  .left_join(:Reactants, [:ReactionID])
                  .left_join(:Species, Name: :Species)
                  .to_hash_groups(:ReactionID)
      products = DB[:Reactions]
                 .where(ReactionID: reaction_ids)
                 .left_join(:Products, [:ReactionID])
                 .left_join(:Species, Name: :Species)
                 .to_hash_groups(:ReactionID)
      rxns = DB[:Reactions]
             .from_self(alias: :rxn)
             .where(ReactionID: reaction_ids)
             .left_join(DB[:RatesWeb].from_self(alias: :rw), Rate: :Rate)
             .left_join(DB[:RateTypesWeb].from_self(alias: :rtw), RateTypeWeb: :RateTypeWeb)
             .select(Sequel.lit('rxn.ReactionId, ' \
                                'rxn.ReactionCategory, ' \
                                'rxn.Rate, ' \
                                '\'/\' || rxn.Mechanism || WebRoute AS WebRoute'))
             .to_hash(:ReactionID)

      # And parse into the desired output format
      reaction_ids.map do |id|
        {
          ReactionID: id,
          Rate: rxns[id][:Rate],
          RateURL: rxns[id][:WebRoute],
          Category: rxns[id][:ReactionCategory],
          Products: products[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } },
          Reactants: reactants[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } }
        }
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ModuleLength
end
