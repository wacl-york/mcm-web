# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      def search(term, _mechanism)
        all = get_all()

        criteria = []
        if term[:peroxy] then criteria.push(get_peroxy()) end

        criteria.reduce(all) { |first, second| first.intersect(second) }
      end

      def get_peroxy()
        valid_smarts = ["CO[O]", "[O]OC"]

        peroxy = DB.fetch(
          "SELECT * FROM Species WHERE Smiles NOT NULL AND (substruct_match(Smiles, ?) OR substruct_match(Smiles, ?))",
          valid_smarts[0], valid_smarts[1],
        )

        peroxy
      end

      def get_all()
        DB.fetch("SELECT * FROM Species WHERE Smiles NOT NULL")
      end
    end
  end
end
