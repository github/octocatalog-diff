# frozen_string_literal: true

require_relative '../api/v1/diff'
require_relative 'differ'
require_relative 'display/json'
require_relative 'display/legacy_json'
require_relative 'display/text'

module OctocatalogDiff
  module CatalogDiff
    # Prepare a display of the results from a catalog-diff. Intended that this will contain utility
    # methods but call out to a OctocatalogDiff::CatalogDiff::Display::<something> class to display in
    # the desired format.
    class Display
      # Display the diff in some specified format.
      # @param diff_in [OctocatalogDiff::CatalogDiff::Differ | Array<Diff results>] Diff to display
      # @param options [Hash] Consisting of:
      #          - :header [String] => Header (can be :default to construct header)
      #          - :display_source_file_line [Boolean] => Display manifest filename and line number where declared
      #          - :compilation_from_dir [String] => Directory where 'from' catalog was compiled
      #          - :compilation_to_dir [String] => Directory where 'to' catalog was compiled
      #          - :display_detail_add [Boolean] => Set true to display parameters of newly added resources
      # @param logger [Logger] Logger object
      # @return [String] Text output for provided diff
      def self.output(diff_in, options = {}, logger = nil)
        diff_x = diff_in.is_a?(OctocatalogDiff::CatalogDiff::Differ) ? diff_in.diff : diff_in
        raise ArgumentError, "text_output requires Array<Diff results>; passed in #{diff_in.class}" unless diff_x.is_a?(Array)
        diff = diff_x.map { |x| OctocatalogDiff::API::V1::Diff.factory(x) }

        # req_format means 'requested format' because 'format' has a built-in meaning to Ruby
        req_format = options.fetch(:format, :color_text)

        # Options hash to pass to display method
        opts = {}
        opts[:header] = header(options)
        opts[:display_source_file_line] = options.fetch(:display_source_file_line, false)
        opts[:compilation_from_dir] = options[:compilation_from_dir] || nil
        opts[:compilation_to_dir] = options[:compilation_to_dir] || nil
        opts[:display_detail_add] = options.fetch(:display_detail_add, false)
        opts[:display_datatype_changes] = options.fetch(:display_datatype_changes, false)

        # Call appropriate display method
        case req_format
        when :json
          logger.debug 'Generating JSON output' if logger
          OctocatalogDiff::CatalogDiff::Display::Json.generate(diff, opts, logger)
        when :legacy_json
          logger.debug 'Generating Legacy JSON output' if logger
          OctocatalogDiff::CatalogDiff::Display::LegacyJson.generate(diff, opts, logger)
        when :text
          logger.debug 'Generating non-colored text output' if logger
          OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, opts.merge(color: false), logger)
        when :color_text
          logger.debug 'Generating colored text output' if logger
          OctocatalogDiff::CatalogDiff::Display::Text.generate(diff, opts.merge(color: true), logger)
        else
          raise ArgumentError, "Unrecognized text format '#{req_format}'"
        end
      end

      # Utility method!
      # Construct the header for diffs
      # Default is diff <old_branch_name>/<node_name> <new_branch_name>/<node_name>
      # @param opts [Hash] Options hash from CLI
      # @return [String] Header in indicated format
      def self.header(opts)
        return nil if opts[:no_header]
        return opts[:header] unless opts[:header] == :default
        node = opts.fetch(:node, 'node')
        from_br = opts.fetch(:from_env, 'a')
        to_br = opts.fetch(:to_env, 'b')
        from_br = 'current' if from_br == '.'
        to_br = 'current' if to_br == '.'
        "diff #{from_br}/#{node} #{to_br}/#{node}"
      end

      # Utility method!
      # Go through the 'diff' array, filtering out ignored items and classifying each change
      # as an addition (+), subtraction (-), change (~), or nested change (!). This creates
      # hashes for each type of change that are consumed later for ordering purposes.
      # @param diff [Array<Diff results>] The diff which *must* be in this format
      # @return [Array<Hash of adds, Hash of removes, Hash of changes, Hash of nested] Processed results
      def self.parse_diff_array_into_categorized_hashes(diff)
        only_in_old = {}
        only_in_new = {}
        changed = {}
        diff.each do |diff_obj|
          (type, title, the_rest) = diff_obj[1].split(/\f/, 3)
          key = "#{type}[#{title}]"
          if ['-', '+'].include?(diff_obj[0])
            only_in_old[key] = { diff: diff_obj[2], loc: diff_obj[3] } if diff_obj[0] == '-'
            only_in_new[key] = { diff: diff_obj[2], loc: diff_obj[3] } if diff_obj[0] == '+'
          elsif ['~', '!'].include?(diff_obj[0])
            # HashDiff reports these as diffs for some reason
            next if diff_obj[2].nil? && diff_obj[3].nil?

            # This turns "foo\fbar\fbaz" into hash['foo']['bar']['baz']
            result = the_rest.split(/\f/).reverse.inject(old: diff_obj[2], new: diff_obj[3]) { |a, e| { e => a } }

            # Assign to appropriate variable
            diff = changed.key?(key) ? changed[key][:diff] : {}
            simple_deep_merge!(diff, result)
            changed[key] = { diff: diff, old_loc: diff_obj[4], new_loc: diff_obj[5] }
          else
            raise "Unrecognized diff symbol '#{diff_obj[0]}' in #{diff_obj.inspect}"
          end
        end
        [only_in_new, only_in_old, changed]
      end

      # Utility Method!
      # Deep merge two hashes. (The 'deep_merge' gem seems to de-duplicate arrays so this is a reinvention
      # of the wheel, but a simpler wheel that does just exactly what we need.)
      # @param hash1 [Hash] First object
      # @param hash2 [Hash] Second object
      def self.simple_deep_merge!(hash1, hash2)
        raise ArgumentError, 'First argument to simple_deep_merge must be a hash' unless hash1.is_a?(Hash)
        raise ArgumentError, 'Second argument to simple_deep_merge must be a hash' unless hash2.is_a?(Hash)
        hash2.each do |k, v|
          if v.is_a?(Hash) && hash1[k].is_a?(Hash)
            # We can only merge a hash with a hash. If hash1[k] is something other than a hash, say for example
            # a string, then the merging is NOT invoked and hash1[k] gets directly overwritten in the `else` clause.
            # Also if hash1[k] is nil, it falls through to the `else` clause where it gets set directly to the result
            # hash without needless iterations.
            simple_deep_merge!(hash1[k], v)
          else
            hash1[k] = v
          end
        end
      end
    end
  end
end
