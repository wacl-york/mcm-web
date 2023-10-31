# frozen_string_literal: true

module MCM
  module Export
    # Exporter into Facsimile format
    class KPP
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = '.kpp'

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength
      def export(species, rxns, rates, root_species, missing_peroxies, peroxies, citation, generic: false)
        # TODO
        ""
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize
    end
  end
end
