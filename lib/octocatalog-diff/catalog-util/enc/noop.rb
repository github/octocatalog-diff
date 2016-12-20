# frozen_string_literal: true

module OctocatalogDiff
  module CatalogUtil
    class ENC
      # No-op ENC.
      class Noop
        # Constructor
        def initialize(_options)
        end

        # Retrieve content
        def content
          ''
        end

        # Error message
        def error_message
          nil
        end
      end
    end
  end
end
