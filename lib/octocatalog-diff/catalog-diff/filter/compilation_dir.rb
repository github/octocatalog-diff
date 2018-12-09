# frozen_string_literal: true

require_relative '../filter'
require_relative '../../util/util'

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
          if diff.change?
            o = remove_compilation_dir(diff.old_value, dir2)
            n = remove_compilation_dir(diff.new_value, dir1)

            if o != diff.old_value || n != diff.new_value
              message = "Resource key #{diff.type}[#{diff.title}] #{diff.structure.join(' => ')}"
              message += ' may depend on catalog compilation directory, but there may be differences.'
              message += ' This is included in results for now, but please verify.'
              @logger.warn message
            end

            if o == n
              message = "Resource key #{diff.type}[#{diff.title}] #{diff.structure.join(' => ')}"
              message += ' appears to depend on catalog compilation directory. Suppressed from results.'
              @logger.warn message
              return true
            end
          end

          false
        end

        def remove_compilation_dir(v, dir)
          value = OctocatalogDiff::Util::Util.deep_dup(v)
          traverse(value) do |e|
            e.gsub!(dir, '') if e.respond_to?(:gsub!)
          end
          value
        end

        def traverse(a)
          case a
          when Array
            a.map { |v| traverse(v, &Proc.new) }
          when Hash
            traverse(a.values, &Proc.new)
          else
            yield a
          end
        end
      end
    end
  end
end
