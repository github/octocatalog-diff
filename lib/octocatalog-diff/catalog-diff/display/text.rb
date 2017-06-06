# frozen_string_literal: true

require_relative '../display'
require_relative '../../util/colored'
require_relative '../../util/util'

require 'diffy'
require 'json'

module OctocatalogDiff
  module CatalogDiff
    class Display
      # Display the output from a diff in text format. Uses the 'diffy' gem to provide diffs in
      # blocks of text. Formats results in a logical Puppet output.
      class Text < OctocatalogDiff::CatalogDiff::Display
        SEPARATOR = '*******************************************'.freeze

        # Generate the text representation of the 'diff' suitable for rendering in a console or log.
        # @param diff [Array<Diff results>] The diff which *must* be in this format
        # @param options_in [Hash] Options which are:
        #           - :color => [Boolean] True or false, whether to use color codes
        #           - :header => [String] Header to print; no header is printed if not specified
        #           - :display_source_file_line [Boolean] True or false, print filename and line (if known)
        #           - :display_detail_add [Boolean] If true, print details of any added resources
        # @param logger [Logger] Logger object
        # @return [Array<String>] Results
        def self.generate(diff, options_in = {}, logger = nil)
          # Empty?
          return [] if diff.empty?

          # We may modify this for temporary local use, but don't want to pass these changes
          # back to the rest of the program.
          options = options_in.dup

          # Enable color support if requested...
          String.colors_enabled = options.fetch(:color, true)

          previous_diffy_default_format = Diffy::Diff.default_format
          Diffy::Diff.default_format = options.fetch(:color, true) ? :color : :text

          # Strip out differences or update display where string matches but data type differs.
          # For example, 28 (the integer) and "28" (the string) have identical string
          # representations, but are different data types. Same for nil vs. "".
          adjust_for_display_datatype_changes(diff, options[:display_datatype_changes], logger)

          # Call the utility method to sort changes into their respective types
          only_in_new, only_in_old, changed = parse_diff_array_into_categorized_hashes(diff)
          sorted_list = only_in_old.keys | only_in_new.keys | changed.keys
          sorted_list.sort!
          unless logger.nil?
            logger.debug "Added resources: #{only_in_new.keys.count}"
            logger.debug "Removed resources: #{only_in_old.keys.count}"
            logger.debug "Changed resources: #{changed.keys.count}"
          end

          # Run through the list to build the result
          result = []
          sorted_list.each do |item|
            # Print the header if needed
            unless options[:header].nil?
              result << options[:header] unless options[:header].empty?
              result << SEPARATOR
              options[:header] = nil
            end

            # A removed item appears only in the old hash.
            if only_in_old.key?(item)
              result.concat display_removed_item(
                item: item,
                old_loc: only_in_old[item][:loc],
                options: options,
                logger: logger
              )

            # An added item appears only in the new hash.
            elsif only_in_new.key?(item)
              result.concat display_added_item(
                item: item,
                new_loc: only_in_new[item][:loc],
                diff: only_in_new[item][:diff],
                options: options,
                logger: logger
              )

            # A change can appear either in the change hash, the nested hash, or both.
            # Therefore, changes and nested changes are combined for display.
            elsif changed.key?(item)
              result.concat display_changed_or_nested_item(
                item: item,
                old_loc: changed[item][:old_loc],
                new_loc: changed[item][:new_loc],
                diff: changed[item][:diff],
                options: options,
                logger: logger
              )

            # An unrecognized change throws an error. This indicates a bug.
            else
              # :nocov:
              raise "BUG (please report): Unable to determine diff type of item: #{item.inspect}"
              # :nocov:
            end
            result << SEPARATOR
          end

          # Reset the global color-related flags
          String.colors_enabled = false
          Diffy::Diff.default_format = previous_diffy_default_format

          # The end
          result
        end

        # Display a changed or nested item
        # @param item [String] Item (type+title) that has changed
        # @param old_loc [Hash] File and line number of location in "from" catalog
        # @param new_loc [Hash] File and line number of location in "to" catalog
        # @param diff [Hash] Difference hash
        # @param options [Hash] Display options
        # @param logger [Logger] Logger object
        # @return [Array] Lines of text
        def self.display_changed_or_nested_item(opts = {})
          item = opts.fetch(:item)
          old_loc = opts.fetch(:old_loc)
          new_loc = opts.fetch(:new_loc)
          diff = opts.fetch(:diff)
          options = opts.fetch(:options)
          logger = opts[:logger]

          result = []
          info_hash = { item: item, result: result, old_loc: old_loc, new_loc: new_loc, options: options, logger: logger }
          add_source_file_line_info(info_hash)
          result << "  #{item} =>"
          diff.keys.sort.each { |key| result.concat hash_diff(diff[key], 1, key, true) }
          result
        end

        # Display a removed item
        # @param item [String] Item (type+title) that has changed
        # @param old_loc [Hash] File and line number of location in "from" catalog
        # @param options [Hash] Display options
        # @param logger [Logger] Logger object
        # @return [Array] Lines of text
        def self.display_removed_item(opts = {})
          item = opts.fetch(:item)
          old_loc = opts.fetch(:old_loc)
          options = opts.fetch(:options)
          logger = opts[:logger]

          result = []
          add_source_file_line_info(item: item, result: result, old_loc: old_loc, options: options, logger: logger)
          result << "- #{item}".red
        end

        # Display an added item
        # @param item [String] Item (type+title) that has changed
        # @param new_loc [Hash] File and line number of location in "to" catalog
        # @param diff [Hash] Difference hash
        # @param options [Hash] Display options
        # @param logger [Logger] Logger object
        # @return [Array] Lines of text
        def self.display_added_item(opts = {})
          item = opts.fetch(:item)
          new_loc = opts.fetch(:new_loc)
          diff = opts.fetch(:diff)
          options = opts.fetch(:options)
          logger = opts[:logger]

          result = []
          add_source_file_line_info(item: item, result: result, new_loc: new_loc, options: options, logger: logger)
          if options[:display_detail_add] && diff.key?('parameters')
            limit = options.fetch(:truncate_details, true) ? 80 : nil
            result << "+ #{item} =>".green
            result << '   parameters =>'.green
            result.concat(
              diff_two_hashes_with_diffy(
                depth: 1,
                hash2: Hash[diff['parameters'].sort], # Should work with somewhat older rubies too
                limit: limit,
                strip_diff: true
              ).map(&:green)
            )
          else
            result << "+ #{item}".green
            if diff.key?('parameters') && logger && !options[:display_detail_add_notice_printed]
              logger.info 'Note: you can use --display-detail-add to view details of added resources'
              options[:display_detail_add_notice_printed] = true
            end
          end

          result
        end

        # Generate info about the source of the change. Pass in parameters as a hash with indicated names.
        # @param item [Hash] Item that is added/removed/changed
        # @param result [Array] Result array (modified by this method)
        # @param old_loc [Hash] Old location hash { file => ..., line => ... }
        # @param new_loc [Hash] New location hash { file => ..., line => ... }
        # @param options [Hash] Options hash
        # @param logger [Logger] Logger object
        def self.add_source_file_line_info(opts = {})
          item = opts.fetch(:item)
          result = opts.fetch(:result)
          old_loc = opts[:old_loc]
          new_loc = opts[:new_loc]
          options = opts.fetch(:options, {})
          logger = opts[:logger]

          # Initialize any currently undefined settings
          empty_hash = { 'file' => nil, 'line' => nil }
          old_loc ||= empty_hash
          new_loc ||= empty_hash
          return if old_loc == empty_hash && new_loc == empty_hash

          # Convert old_loc and new_loc to strings
          old_loc_string = loc_string(old_loc, options[:compilation_from_dir], logger)
          new_loc_string = loc_string(new_loc, options[:compilation_to_dir], logger)

          # Debug log information and build up local_result with printable changes
          local_result = []
          if old_loc == new_loc || new_loc == empty_hash || old_loc_string == new_loc_string
            logger.debug "#{item} @ #{old_loc_string || 'nil'}" if logger
            local_result << "  #{old_loc_string}".cyan unless old_loc_string.nil?
          elsif old_loc == empty_hash
            logger.debug "#{item} @ #{new_loc_string || 'nil'}" if logger
            local_result << "  #{new_loc_string}".cyan unless new_loc_string.nil?
          else
            logger.debug "#{item} -@ #{old_loc_string} +@ #{new_loc_string}" if logger
            local_result << "- #{old_loc_string}".cyan
            local_result << "+ #{new_loc_string}".cyan
          end

          # Only modify result if option to display source file and line is enabled
          result.concat local_result if options[:display_source_file_line]
        end

        # Convert { file => ..., line => ... } to displayable string
        # @param loc [Hash] file => ..., line => ... hash
        # @param compilation_dir [String] Compilation directory
        # @param logger [Logger] Logger object
        # @return [String] Location string
        def self.loc_string(loc, compilation_dir, logger)
          return nil if loc.nil? || !loc.is_a?(Hash) || loc['file'].nil? || loc['line'].nil?
          result = "#{loc['file']}:#{loc['line']}"
          if compilation_dir
            rex = Regexp.new('^' + Regexp.escape(compilation_dir + '/'))
            result_new = result.sub(rex, '')
            if result_new != result
              logger.debug "Removed compilation directory in #{result} -> #{result_new}" if logger
              result = result_new
            end
          end
          result
        end

        # Get the diff of two long strings. Call the 'diffy' gem for this.
        # @param string1 [String] First string (-)
        # @param string2 [String] Second string (+)
        # @param depth [Integer] Depth, for correct indentation
        # @return Array<String> Displayable result
        def self.diff_two_strings_with_diffy(string1, string2, depth)
          # Single line strings?
          if single_lines?(string1, string2)
            string1, string2 = add_trailing_newlines(string1, string2)
            diff = Diffy::Diff.new(string1, string2, context: 2, include_diff_info: false).to_s.split("\n")
            return diff.map { |x| left_pad(2 * depth + 2, make_trailing_whitespace_visible(adjust_position_of_plus_minus(x))) }
          end

          # Multiple line strings
          string1, string2 = add_trailing_newlines(string1, string2)
          diff = Diffy::Diff.new(string1, string2, context: 2, include_diff_info: true).to_s.split("\n")
          diff.shift # Remove first line of diff info (filename that makes no sense)
          diff.shift # Remove second line of diff info (filename that makes no sense)
          diff.map { |x| left_pad(2 * depth + 2, make_trailing_whitespace_visible(x)) }
        end

        # Determine if two incoming strings are single lines. Returns true if both
        # incoming strings are single lines, false otherwise.
        # @param string_1 [String] First string
        # @param string_2 [String] Second string
        # @return [Boolean] Whether both incoming strings are single lines
        def self.single_lines?(string_1, string_2)
          string_1.strip !~ /\n/ && string_2.strip !~ /\n/
        end

        # Add "\n" to the end of both strings, only if both strings are lacking it.
        # This prevents "\\ No newline at end of file" for single string comparison.
        # @param string_1 [String] First string
        # @param string_2 [String] Second string
        # @return [Array<String>] Adjusted string_1, string_2
        def self.add_trailing_newlines(string_1, string_2)
          return [string_1, string_2] unless string_1 !~ /\n\Z/ && string_2 !~ /\n\Z/
          [string_1 + "\n", string_2 + "\n"]
        end

        # Adjust the space after of the `-` / `+` in the diff for single line diffs.
        # Diffy prints diffs with no space between the `-` / `+` in the text, but for
        # single lines it's easier to read with that space added.
        # @param string_in [String] Input string, which is a line of a diff from diffy
        # @return [String] Modified string
        def self.adjust_position_of_plus_minus(string_in)
          string_in.sub(/\A(\e\[\d+m)?([\-\+])/, '\1\2 ')
        end

        # Convert trailing whitespace to underscore for display purposes. Also convert special
        # whitespace (\r, \n, \t, ...) to character representation.
        # @param string_in [String] Input string, which might contain trailing whitespace
        # @return [String] Modified string
        def self.make_trailing_whitespace_visible(string_in)
          return string_in unless string_in =~ /\A((?:.|\n)*?)(\s+)(\e\[0m)?\Z/
          beginning = Regexp.last_match(1)
          trailing_space = Regexp.last_match(2)
          end_escape = Regexp.last_match(3)

          # Trailing space adjustment for line endings
          trailing_space.gsub! "\n", '\n'
          trailing_space.gsub! "\r", '\r'
          trailing_space.gsub! "\t", '\t'
          trailing_space.gsub! "\f", '\f'
          trailing_space.tr! ' ', '_'

          [beginning, trailing_space, end_escape].join('')
        end

        # Get the diff of two hashes. Call the 'diffy' gem for this.
        # @param hash1 [Hash] First hash (-)
        # @param hash1 [Hash] Second hash (+)
        # @param depth [Integer] Depth, for correct indentation
        # @param limit [Integer] Maximum string length
        # @param strip_diff [Boolean] Strip leading +/-/" "
        # @return [Array<String>] Displayable result
        def self.diff_two_hashes_with_diffy(opts = {})
          depth = opts.fetch(:depth, 0)
          hash1 = opts.fetch(:hash1, {})
          hash2 = opts.fetch(:hash2, {})
          limit = opts[:limit]
          strip_diff = opts.fetch(:strip_diff, false)

          # Special case: addition only, no truncation
          return addition_only_no_truncation(depth, hash2) if hash1 == {} && limit.nil?

          json_old = stringify_for_diffy(hash1)
          json_new = stringify_for_diffy(hash2)

          # If stripping the diff, we need to make sure diffy does not colorize the output, so that
          # there are not color codes in the output to deal with.
          diff = if strip_diff
            Diffy::Diff.new(json_old, json_new, context: 0).to_s(:text).split("\n")
          else
            Diffy::Diff.new(json_old, json_new, context: 0).to_s.split("\n")
          end
          raise "Diffy diff empty for string: #{json_old}" if diff.empty?

          # This is the array that is returned
          diff.map do |x|
            x = x[2..-1] if strip_diff # Drop first 2 characters: '+ ', '- ', or '  '
            truncate_string(left_pad(2 * depth + 2, x), limit)
          end
        end

        # Special case: addition only, no truncation
        # @param depth [Integer] Depth, for correct indentation
        # @param hash [Hash] Added object
        # @return [Array<String>] Displayable result
        def self.addition_only_no_truncation(depth, hash)
          result = []

          # Single line strings
          hash.keys.sort.map do |key|
            next if hash[key] =~ /\n/
            result << left_pad(2 * depth + 4, [key.inspect, ': ', hash[key].inspect].join('')).green
          end

          # Multi-line strings
          hash.keys.sort.map do |key|
            next if hash[key] !~ /\n/
            result << left_pad(2 * depth + 4, [key.inspect, ': >>>'].join('')).green
            result.concat hash[key].split(/\n/).map(&:green)
            result << '<<<'.green
          end

          result
        end

        # Limit length of a string
        # @param str [String] String
        # @param limit [Integer] Limit (0=unlimited)
        # @return [String] Truncated string
        def self.truncate_string(str, limit)
          return str if limit.nil? || str.length <= limit
          "#{str[0..limit]}..."
        end

        # Get the diff between two hashes. This is recursive-aware.
        # @param obj [diff object] diff object
        # @param depth [Integer] Depth of nesting, used for indentation
        # @return Array<String> Printable diff outputs
        def self.hash_diff(obj, depth, key_in, nested = false)
          result = []
          result << left_pad(2 * depth, " #{key_in} =>")
          if obj.key?(:old) && obj.key?(:new)
            if nested && obj[:old].is_a?(Hash) && obj[:new].is_a?(Hash)
              # Nested hashes will be stringified and then use 'diffy'
              result.concat diff_two_hashes_with_diffy(depth: depth, hash1: obj[:old], hash2: obj[:new])
            elsif obj[:old].is_a?(String) && obj[:new].is_a?(String)
              # Strings will use 'diffy' to mimic the output seen when using
              # "diff" on the command line.
              result.concat diff_two_strings_with_diffy(obj[:old], obj[:new], depth)
            else
              # Stuff we don't recognize will be converted to a string and printed
              # with '+' and '-' unless the object resolves to an empty string.
              result.concat diff_at_depth(depth, obj[:old], obj[:new])
            end
          else
            obj.keys.sort.each { |key| result.concat hash_diff(obj[key], 1 + depth, key, nested) }
          end
          result
        end

        # Get the diff between two arbitrary objects
        # @param depth [Integer] Depth of nesting, used for indentation
        # @param old_obj [?] Old object
        # @param new_obj [?] New object
        # @return Array<String> Diff output
        def self.diff_at_depth(depth, old_obj, new_obj)
          old_s = old_obj.to_s
          new_s = new_obj.to_s
          result = []
          result << left_pad(2 * depth + 2, "- #{old_s}").red unless old_s == ''
          result << left_pad(2 * depth + 2, "+ #{new_s}").green unless new_s == ''
          result
        end

        # Utility Method!
        # Indent a given text string with a certain number of spaces
        # @param spaces [Integer] Number of spaces
        # @param text [String] Text
        def self.left_pad(spaces, text = '')
          [' ' * spaces, text].join('')
        end

        # Utility Method!
        # Harmonize equivalent class names for comparison purposes.
        # @param class_name [String] Class name as input
        # @return [String] Class name as output
        def self.class_name_for_diffy(class_name)
          return 'Integer' if class_name == 'Fixnum'
          class_name
        end

        # Utility Method!
        # Given an arbitrary object, convert it into a string for use by 'diffy'.
        # This basically exists so we can do something prettier than just calling .inspect or .to_s
        # on object types we anticipate seeing, while not failing entirely on other object types.
        # @param obj [?] Object to be stringified
        # @return [String] String representation of object for diffy
        def self.stringify_for_diffy(obj)
          return JSON.pretty_generate(obj) if OctocatalogDiff::Util::Util.object_is_any_of?(obj, [Hash, Array])
          return '""' if obj.is_a?(String) && obj == ''
          return obj if OctocatalogDiff::Util::Util.object_is_any_of?(obj, [String, Fixnum, Integer, Float])
          "#{class_name_for_diffy(obj.class)}: #{obj.inspect}"
        end

        # Utility Method!
        # Implement the --display-datatype-changes option by:
        # - Removing string-equivalent differences when option == false
        # - Updating display of string-equivalent differences when option == true
        # @param diff [Array<Diff Objects>] Difference array
        # @param option [Boolean] Selected behavior; see description
        # @param logger [Logger] Logger object
        def self.adjust_for_display_datatype_changes(diff, option, logger = nil)
          diff.map! do |diff_obj|
            if diff_obj[0] == '+' || diff_obj[0] == '-'
              diff_obj[2] = 'undef' if diff_obj[2].nil?
              diff_obj
            else
              x2, x3 = _adjust_for_display_datatype(diff_obj[2], diff_obj[3], option, logger)
              if x2.nil? && x3.nil?
                # Delete this! Return nil and compact! will get rid of them.
                msg = "Adjust display for #{diff_obj[1].gsub(/\f/, '::')}: " \
                      "#{diff_obj[2].inspect} != #{diff_obj[3].inspect} DELETED"
                logger.debug(msg) if logger
                nil
              elsif x2 == diff_obj[2] && x3 == diff_obj[3]
                # Neither object changed
                diff_obj
              else
                # Adjust the display and return modified object
                msg = "Adjust display for #{diff_obj[1].gsub(/\f/, '::')}: " \
                      "old=#{x2.inspect} new=#{x3.inspect} "\
                      "(extra debugging: #{diff_obj[2].inspect} -> #{x2}; "\
                      "#{diff_obj[3].inspect} -> #{x3})"
                logger.debug(msg) if logger
                diff_obj[2] = x2
                diff_obj[3] = x3
                diff_obj
              end
            end
          end
          diff.compact!
        end

        # Utility Method!
        # Called by adjust_for_display_datatype_changes to compare an old value
        # to a new value and adjust as appropriate.
        # @param obj1 [?] First object
        # @param obj2 [?] Second object
        # @param option [Boolean] Selected behavior; see adjust_for_display_datatype_changes
        # @return [<String, String> or <?, ?>] Updated values of objects
        def self._adjust_for_display_datatype(obj1, obj2, option, logger)
          # If not string-equal, return to leave untouched
          return [obj1, obj2] unless obj1.to_s == obj2.to_s

          # Delete if option to display these is false
          return [nil, nil] unless option

          # Delete if both objects are nil
          return [nil, nil] if obj1.nil? && obj2.nil?

          # If one is nil and the other is the empty string...
          return ['undef', '""'] if obj1.nil?
          return ['""', 'undef'] if obj2.nil?

          # If one is an integer and the other is a string
          return [obj1, "\"#{obj2}\""] if obj1.is_a?(Integer) && obj2.is_a?(String)
          return ["\"#{obj1}\"", obj2] if obj1.is_a?(String) && obj2.is_a?(Integer)

          # True and false
          return [obj1, "\"#{obj2}\""] if obj1.is_a?(TrueClass) && obj2.is_a?(String)
          return [obj1, "\"#{obj2}\""] if obj1.is_a?(FalseClass) && obj2.is_a?(String)
          return ["\"#{obj1}\"", obj2] if obj1.is_a?(String) && obj2.is_a?(TrueClass)
          return ["\"#{obj1}\"", obj2] if obj1.is_a?(String) && obj2.is_a?(FalseClass)

          # Unhandled case - warn about it and then return inputs untouched
          # Note: If you encounter this, please report it so we can add a handler.
          # :nocov:
          msg = "In _adjust_for_display_datatype, objects '#{obj1.inspect}' (#{obj1.class}) and"\
                " '#{obj2.inspect}' (#{obj2.class}) have identical string representations but"\
                ' formatting is not implemented to update display.'
          logger.warn(msg) if logger
          [obj1, obj2]
          # :nocov:
        end
      end
    end
  end
end
