# frozen_string_literal: true

module MCM
  module Export
    # Fallback Exporter
    class Fallback
      # Fallback exporter format
      CONTENT_TYPE = 'text/plain'
      FILE_EXTENSION = '.txt'

      # TODO: Could make this return plain text?
      def export(*)
        raise 'Unknown export method selected.'
      end
    end
  end
end
