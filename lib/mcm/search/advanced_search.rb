# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      def search(term, _mechanism)
        all = find_all

        criteria = []
        criteria.push(find_radical) if term[:radical]
        criteria.push(find_peroxy) if term[:peroxy]

        criteria.reduce(all) { |first, second| first.intersect(second) }
      end

      def find_radical
        valid_smarts = ['[O]']

        DB[:Species]
          .exclude(Smiles: nil)
          .where(Sequel.lit('substruct_match(Smiles, ?)', valid_smarts[0]))
      end

      def find_peroxy
        valid_smarts = ['CO[O]', '[O]OC']

        DB[:Species]
          .exclude(Smiles: nil)
          .where(Sequel.lit('substruct_match(Smiles, ?) OR substruct_match(Smiles, ?)',
                            valid_smarts[0], valid_smarts[1]))
      end

      def find_all
        DB[:Species].exclude(Smiles: nil)
      end

      def extract_elements(inchi)
        formula = inchi.split('/')[1]
        elements = {}

        elem = 'initial'
        num = ''

        formula.each_char do |char|
          case char
          when /\d/
            num << char
          when /[[:lower:]]/
            elem << char
          when /[[:upper:]]/
            if elem != 'initial'
              num = '1' if num == ''
              elements[elem] = num.to_i
              num = ''
            end

            elem = char
          end
        end

        # Final element
        num = '1' if num == ''
        elements[elem] = num.to_i

        elements
      end
    end
  end
end
