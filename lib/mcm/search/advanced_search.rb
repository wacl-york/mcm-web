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
        criteria.push(find_peroxy) if term[:peroxy]

        criteria.push(find_elements({
                                      'C' => term[:elemc],
                                      'Cl' => term[:elemcl],
                                      'H' => term[:elemh],
                                      'N' => term[:elemn],
                                      'O' => term[:elemo],
                                      'S' => term[:elems]
                                    }))

        criteria.push(find_by_amw(term[:amw].to_f)) unless term[:amw].empty?

        criteria.reduce(all) { |first, second| first.intersect(second) }
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def substruct_match(valid_smarts)
        return if valid_smarts.empty?

        query = "substruct_match(Smiles, ?)#{'OR substruct_match(Smiles, ?)' * (valid_smarts.length - 1)}"

        DB[:Species]
          .exclude(Smiles: nil)
          .where(Sequel.lit(query, *valid_smarts))
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
        tolerance = 1.0

        DB[:Species]
          .exclude(Smiles: nil)
          .where { mass > amw - tolerance }
          .where { mass < amw + tolerance }
      end

      def find_all
        DB[:Species]
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
