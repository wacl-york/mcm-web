# frozen_string_literal: true

module MCM
  module Search
    # Advanced seach functionalities
    module Advanced
      module_function

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def search(term, _mechanism)
        all = find_all

        criteria = []
        criteria.push(find_radical) if term[:radical]
        criteria.push(find_peroxy) unless term[:peroxy]

        criteria.push(find_elements({
                                      'C' => term[:elemc],
                                      'Cl' => term[:elemcl],
                                      'O' => term[:elemo],
                                      'H' => term[:elemh],
                                      'N' => term[:elemn],
                                      'S' => term[:elems]
                                    }))

        criteria.push(find_by_amw(term[:amw].to_f)) unless term[:amw].empty?

        criteria.reduce(all) { |first, second| first.intersect(second) }
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

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

        matching_inchi = all.filter do |inchi|
          makeup = extract_elements(inchi)
          element_match?(element_counts, makeup)
        end

        DB[:Species].where(Inchi: matching_inchi)
      end

      def find_by_amw(amw)
        tolerance = 0.5

        DB[:Species]
          .exclude(Smiles: nil)
          .where(Sequel.lit('CAST(get_descriptor(Smiles, "amw") AS decimal) BETWEEN ? AND ?',
                            amw - tolerance, amw + tolerance))
      end

      def find_all
        DB[:Species].exclude(Smiles: nil)
      end

      def extract_elements(inchi)
        formula = inchi.split('/')[1]
        query = /([A-Z][a-z]*)(\d*)/
        elements = {}

        formula.scan(query).each do |(elem, num)|
          num = '1' if num.empty?
          elements[elem] = num.to_i
        end

        elements
      end

      def element_match?(requested, actual)
        requested.each do |elem, count|
          return false if count == '0' && actual.key?(elem)
          return false if count.to_i.positive? && actual[elem] != count.to_i
        end

        true
      end
    end
  end
end
