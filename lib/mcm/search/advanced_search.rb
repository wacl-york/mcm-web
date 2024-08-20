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

        criteria.push(find_elements({
                                      'C' => term[:elemc],
                                      'Cl' => term[:elemcl],
                                      'O' => term[:elemo],
                                      'H' => term[:elemh],
                                      'N' => term[:elemn]
                                    }))

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

      def find_elements(element_counts)
        all = DB[:Species].select(:Inchi).exclude(Inchi: nil).map { |x| x[:Inchi] }

        valid_inchi = all.filter do |inchi|
          makeup = extract_elements(inchi)
          fail_flag = false

          element_counts.each do |elem, count|
            case count
            when '0'
              fail_flag = true unless makeup.key?(elem)
            when /[1-9][0-9]*/
              fail_flag = true if makeup[elem] != count.to_i
            end
          end

          !fail_flag
        end

        DB[:Species].where(Inchi: valid_inchi)
      end

      def find_all
        DB[:Species].exclude(Smiles: nil)
      end

      def extract_elements(inchi)
        formula = inchi.split('/')[1]
        elements = {}

        elem = +'initial'
        num = +''

        formula.each_char do |char|
          case char
          when /\d/
            num << char
          when /[[:lower:]]/
            elem << char
          when /[[:upper:]]/
            if elem != 'initial'
              num = +'1' if num == ''
              elements[elem] = num.to_i
              num = +''
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
