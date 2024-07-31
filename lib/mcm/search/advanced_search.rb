# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      def search(term, _mechanism)
        all = find_all

        criteria = []
        criteria.push(find_peroxy) if term[:peroxy]

        criteria.reduce(all) { |first, second| first.intersect(second) }
      end

      def find_peroxy
        valid_smarts = ['CO[O]', '[O]OC']

        DB.fetch(
          'SELECT * FROM Species WHERE Smiles NOT NULL AND (substruct_match(Smiles, ?) OR substruct_match(Smiles, ?))',
          valid_smarts[0], valid_smarts[1]
        )
      end

      def find_all
        DB.fetch('SELECT * FROM Species WHERE Smiles NOT NULL')
      end
    end
  end
end
