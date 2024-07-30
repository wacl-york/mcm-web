# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      def search(_term, _mechanism)
        results_valid = get_all()
        results_peroxy = get_peroxy()

        results_all = results_valid
                      .union(results_peroxy)

        results_all
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
        all = DB.fetch("SELECT * FROM Species WHERE Smiles NOT NULL")
        all
      end
    end
  end
end
