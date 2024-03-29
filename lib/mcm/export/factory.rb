# frozen_string_literal: true

module MCM
  module Export
    # Factory method for submechanism exporter
    module Factory
      module_function

      # rubocop:disable Metrics/MethodLength
      def exporter_factory(format)
        # Returns the selected export format
        #
        # Args:
        #   - format: String representing which format to use
        #
        # Returns:
        #   A function that can export the mechanism
        case format
        when 'facsimile'
          MCM::Export::Facsimile.new
        when 'kpp'
          MCM::Export::KPP.new
        when 'species_tsv'
          MCM::Export::SpeciesTSV.new
        else
          puts "Unknown export format '#{format}'"
          MCM::Export::Fallback.new
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
