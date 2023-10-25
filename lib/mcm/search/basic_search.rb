# frozen_string_literal: true

module MCM
  module Search
    # Basic seach functionalities
    module Basic
      module_function

      def find_species(term, preceeding: false)
        search_pattern = "#{term}%"
        search_pattern = "%#{search_pattern}" if preceeding
        DB[:species]
          .where(Sequel.ilike(:Name, search_pattern))
          .select(:Name)
      end

      def find_synonym(term, preceeding: false)
        search_pattern = "#{term}%"
        search_pattern = "%#{search_pattern}" if preceeding
        DB[:speciessynonyms]
          .where(Sequel.ilike(:Synonym, search_pattern))
      end

      def find_smiles(term)
        search_pattern = "%#{term}%"
        DB[:species]
          .where(Sequel.ilike(:Smiles, search_pattern))
          .select(:Name)
      end

      def find_inchi(term)
        # TODO: should append Inchi string if not available (i.e. should users be expected to
        # search for InChI=1S/C3H2...., or should C3H2 return results?
        search_pattern = "#{term}%"
        DB[:species]
          .where(Sequel.ilike(:Inchi, search_pattern))
          .select(:Name)
      end
    end
  end
end
