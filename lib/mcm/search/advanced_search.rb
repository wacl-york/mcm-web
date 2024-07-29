# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      def search(_term, _mechanism)
        peroxy = get_peroxy()
        puts peroxy.all
        peroxy
      end

      def get_peroxy()
        valid_smarts = ["CO[O]", "[O]OC"]

        peroxy = DB.fetch(
          "SELECT * FROM Species WHERE substruct_match(Smiles, ?) OR substruct_match(Smiles, ?)",
          valid_smarts[0], valid_smarts[1],
        )

        peroxy
      end
    end
  end
end
