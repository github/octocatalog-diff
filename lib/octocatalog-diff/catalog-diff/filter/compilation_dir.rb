# frozen_string_literal: true

require_relative '../filter'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes that are due to the catalog compilation directory.
      class CompilationDir < OctocatalogDiff::CatalogDiff::Filter
        # Public: Filter the diff if the change is due to the catalog compilation directory.
        # Determine this by obtaining the compiilation directory from each of the catalogs
        # (supplied via options) and checking the differences. If the only thing different
        # is the compilation directory, filter it out with a warning.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param options [Hash] Additional options:
        #   :from_compilation_dir [String] Compilation directory for the "from" catalog
        #   :to_compilation_dir [String] Compilation directory for the "to" catalog
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, options = {})
          return false unless options[:from_compilation_dir] && options[:to_compilation_dir]
          dir1 = options[:to_compilation_dir]
          dir1_rexp = Regexp.escape(dir1)
          dir2 = options[:from_compilation_dir]
          dir2_rexp = Regexp.escape(dir2)
          dir = Regexp.new("(?:#{dir1_rexp}|#{dir2_rexp})")

          # Check for added/removed resources where the title of the resource includes the compilation directory
          if (diff.addition? || diff.removal?) && diff.title.match(dir)
            message = "Resource #{diff.type}[#{diff.title}]"
            message += ' appears to depend on catalog compilation directory. Suppressed from results.'
            logger.warn message
            return true
          end

          # Check for a change where the difference in a parameter exactly corresponds to the difference in the
          # compilation directory.
          if diff.change? && (diff.old_value.is_a?(String) || diff.new_value.is_a?(String))
            from_before = nil
            from_after = nil
            from_match = false
            to_before = nil
            to_after = nil
            to_match = false

            if diff.old_value =~ /^(.*)#{dir2}(.*)$/m
              from_before = Regexp.last_match(1) || ''
              from_after = Regexp.last_match(2) || ''
              from_match = true
            end

            if diff.new_value =~ /^(.*)#{dir1}(.*)$/m
              to_before = Regexp.last_match(1) || ''
              to_after = Regexp.last_match(2) || ''
              to_match = true
            end

            if from_match && to_match && to_before == from_before && to_after == from_after
              message = "Resource key #{diff.type}[#{diff.title}] #{diff.structure.join(' => ')}"
              message += ' appears to depend on catalog compilation directory. Suppressed from results.'
              @logger.warn message
              return true
            end

            if from_match || to_match
              message = "Resource key #{diff.type}[#{diff.title}] #{diff.structure.join(' => ')}"
              message += ' may depend on catalog compilation directory, but there may be differences.'
              message += ' This is included in results for now, but please verify.'
              @logger.warn message
            end
          end

          false
        end
      end
    end
  end
end
