# frozen_string_literal: true

require 'diffy'
require 'hashdiff'
require 'json'
require 'set'
require 'stringio'

require_relative '../catalog'
require_relative '../errors'
require_relative 'filter'

module OctocatalogDiff
  module CatalogDiff
    # Calculate the difference between two Puppet catalogs.
    # -----------------------------------------------------
    # It was necessary to write our own code for this, and not just use some existing gem,
    # for two main reasons:
    #
    # 1. There are things that we want to ignore when doing a Puppet catalog diff. For example
    #    we want to ignore 'before' and 'require' parameters (because those affect the order of
    #    operations only, not the end result) and we probably want to ignore 'tags' attributes
    #    and all classes. No existing code (that I could find at least) was capable of allowing
    #    you to skip stuff via arguments, without your own custom pre-processing.
    #
    # 2. When using the 'hashdiff' gem, there is no distinguishing between an addition of an entire
    #    new key-value pair, or the addition of an element in a deeply nested array. By way of
    #    further explanation, consider these two data structures:
    #
    #    a = { 'foo' => 'bar', 'my_array' => [ 1, 2, 3 ] }
    #    b = { 'foo' => 'bar', 'my_array' => [ 1, 2, 3, 4 ], 'another_key' => 'another_value'
    #
    #    The hashdiff gem would report the differences between a and b to be:
    #       + 4
    #       + another_key => another_value
    #
    #    We want to distinguish (without a whole bunch of convoluted code) between these two situations.
    #    One was a true addition (adding a key) while one was a change (adding element to array). This
    #    distinction becomes even more important when considering top-level changes vs. changes to arrays
    #    or hashes nested within the catalog.
    #
    # Therefore, the algorithm implemented here is as follows:
    #
    # 1. Pre-process the catalog JSON files to:
    #    - Sort the 'tags' array, since the order of tags does not matter to Puppet
    #    - Pull out additions of entire key-value pairs (above, 'another_key' => 'another_value')
    #
    # 2. Everything left consists of key-value pairs where the key exists in both old and new. Pass this
    #    to the 'hashdiff' gem.
    #
    # 3. Filter any differences to remove attributes, types, or resources that have been explicitly ignored.
    #
    # 4. Reformat any '+' or '-' reported by hashdiff to be changes to the keys, rather than outright
    #    additions.
    #
    # The heavy lifting is still handled by 'hashdiff' but we're pre-simplifying the input and post-processing
    # the output to make it easier to deal with later.
    class Differ
      # Constructor
      # @param catalog1_in [OctocatalogDiff::Catalog] First catalog to compare
      # @param catalog2_in [OctocatalogDiff::Catalog] Second catalog to compare
      def initialize(opts, catalog1_in, catalog2_in)
        @catalog1_raw = catalog1_in
        @catalog2_raw = catalog2_in
        @catalog1 = catalog_resources(catalog1_in, 'First catalog')
        @catalog2 = catalog_resources(catalog2_in, 'Second catalog')
        @logger = opts.fetch(:logger, Logger.new(StringIO.new))
        @diff_result = nil
        @ignore = Set.new
        ignore(opts.fetch(:ignore, []))
        @opts = opts
      end

      # Difference - calculates and then returns the diff of this objects
      # Each diff result is an array like this:
      #   [ <String> '+|-|~|!', <String> Key name, <Object> Old object, <Object> New object ]
      # @return [Array<Diff results>] Results of the diff
      def diff
        @diff_result ||= catdiff
      end

      # Ignore - ignored items can be set by Type, Title, or Attribute; setting multiple in
      # a hash is interpreted as AND. The collection of all ignored items is interpreted as OR.
      # @param ignore [Hash<type: xxx, title: yyy, attr: zzz>] Ignore type/title/attr (can pass array also)
      # @return [OctocatalogDiff::CatalogDiff::Differ] This object, modified
      def ignore(ignores = [])
        ignore_array = ignores.is_a?(Array) ? ignores : [ignores]
        ignore_array.each do |item|
          raise ArgumentError, "Argument #{item.inspect} to ignore is not a hash" unless item.is_a?(Hash)
          unless item.key?(:type) || item.key?(:title) || item.key?(:attr)
            raise ArgumentError, "Argument #{item.inspect} does not contain :type, :title, or :attr"
          end
          item[:type] ||= '*'
          item[:title] ||= '*'
          item[:attr] ||= '*'

          # Support wildcards in title
          if item[:title].is_a?(String) && item[:title] != '*' && item[:title].include?('*')
            item[:title] = Regexp.new("\\A#{Regexp.escape(item[:title]).gsub('\*', '.*')}\\Z", 'i')
          end

          @ignore.add(item)
        end
        self
      end

      # Handle --ignore-tags option, the ability to tag resources within modules/manifests and
      # have catalog-diff ignore them.
      def ignore_tags
        return unless @opts[:ignore_tags].is_a?(Array) && @opts[:ignore_tags].any?

        # Go through the "to" catalog and identify any resources that have been tagged with one or more
        # specified "ignore tags." Add any such items to the ignore list. The 'to' catalog has the authoritative
        # list of dynamic ignores.
        @catalog2_raw.resources.each do |resource|
          next unless tagged_for_ignore?(resource)
          ignore(type: resource['type'], title: resource['title'])
          @logger.debug "Ignoring type='#{resource['type']}', title='#{resource['title']}' based on tag in to-catalog"
        end

        # Go through the "from" catalog and identify any resources that have been tagged with one or more
        # specified "ignore tags." Only mark the resources for ignoring if they do not appear in the 'to'
        # catalog, thereby allowing the 'to' catalog to be the authoritative ignore list. This allows deleted
        # items that were previously ignored to continue to be ignored.
        @catalog1_raw.resources.each do |resource|
          next if @catalog2_raw.resource(type: resource['type'], title: resource['title'])
          next unless tagged_for_ignore?(resource)
          ignore(type: resource['type'], title: resource['title'])
          @logger.debug "Ignoring type='#{resource['type']}', title='#{resource['title']}' based on tag in from-catalog"
        end
      end

      # Return catalog1 with filter_and_cleanups applied.
      # This is in the public section because it's called from spec tests as well
      # as being called internally.
      # @return [Array<Resource Hashes>] Filtered resources in catalog
      def catalog1
        filter_and_cleanup(@catalog1)
      end

      # Return catalog2 with filter_and_cleanups applied.
      # This is in the public section because it's called from spec tests as well
      # as being called internally.
      # @return [Array<Resource Hashes>] Filtered resources in catalog
      def catalog2
        filter_and_cleanup(@catalog2)
      end

      private

      # Determine if a resource is tagged with any ignore-tag.
      # @param resource [Hash] The resource
      # @return [Boolean] true if tagged for ignore, false if not
      def tagged_for_ignore?(resource)
        return false unless @opts[:ignore_tags].is_a?(Array)
        return false unless resource.key?('tags') && resource['tags'].is_a?(Array)
        @opts[:ignore_tags].each do |tag|
          # tag_with_type will be like: 'ignored_catalog_diff__mymodule__mytype'
          tag_with_type = [tag, resource['type'].downcase.gsub(/\W/, '_')].join('__')
          return true if resource['tags'].include?(tag) || resource['tags'].include?(tag_with_type)
        end
        false
      end

      # Actually perform the catalog diff. This implements the 3-part algorithm described in the
      # comment block at the top of this file.
      def catdiff
        @logger.debug "Entering catdiff; catalog sizes: #{@catalog1.size}, #{@catalog2.size}"

        # Compute '+' and '-' from resources that exist in one catalog but not another.
        # After this returns,
        #   result = Array<'+|-', key, value> (Additions/subtractions of entire resources)
        #   remaining1 & remaining2 = Hash<Serialized Type+Title, Value> (resources in each catalog)
        #   Note that remaining1.keys == remaining2.keys after running this
        result, remaining1, remaining2 = preprocess_diff

        # Call the hashdiff gem.
        # After this returns,
        #   initial_hashdiff_result = Array<'~', key, oldvalue, newvalue>
        #   hashdiff_add_remove = Array<Serialized tokens with nested changes>
        initial_hashdiff_result, hashdiff_add_remove = hashdiff_initial(remaining1, remaining2)
        result.concat initial_hashdiff_result

        # Compute '!' which is elements of arrays or hashes within the 'hashdiff' change set that
        # have been added. See explanation in point #2 in main comment block at the top of this file.
        hashdiff_nested_changes_result = hashdiff_nested_changes(hashdiff_add_remove, remaining1, remaining2)
        result.concat hashdiff_nested_changes_result

        # Remove resources that have been explicitly ignored
        filter_diffs_for_ignored_items(result)

        # Legacy options which are now filters
        @opts[:filters] ||= []
        add_element_to_array(@opts[:filters], 'CompilationDir')
        add_element_to_array(@opts[:filters], 'AbsentFile') if @opts[:suppress_absent_file_details]

        # Apply any additional pluggable filters.
        filter_opts = {
          logger: @logger,
          from_compilation_dir: @catalog1_raw.compilation_dir,
          to_compilation_dir: @catalog2_raw.compilation_dir
        }
        OctocatalogDiff::CatalogDiff::Filter.apply_filters(result, @opts[:filters], filter_opts) if @opts[:filters].any?

        # That's it!
        @logger.debug "Exiting catdiff; change count: #{result.size}"
        result
      end

      # Add an element to an array if it doesn't already exist in that array
      # @param array_in [Array] Array to have element added (**mutated** by this method)
      # @param element [?] Element to add
      def add_element_to_array(array_in, element)
        array_in << element unless array_in.include?(element)
      end

      # Filter the differences for any items that were ignored, by some combination of type, title, and
      # attribute. This modifies the array itself by selecting only items that do not meet the ignored
      # filter.
      def filter_diffs_for_ignored_items(result)
        result.reject! { |item| ignored?(item) }
      end

      # Pre-processing of a catalog.
      # - Remove 'before' and 'require' from parameters
      # - Sort 'tags' array, or remove the tags array if tags are being ignored
      # @param catalog_resources [Array<Hash>] Catalog resources
      # @return [Array<Hash>] Array of cleaned resources
      def filter_and_cleanup(catalog_resources)
        result = []
        catalog_resources.each do |resource|
          # Exported resources are skipped (this is specifically testing that the value is
          # equal to the boolean true, not just that the value exists or something similar)
          next if resource['exported'] == true

          # This will be the modified hash added to result
          hsh = {}
          hsh['type'] = resource.fetch('type', '')
          hsh['title'] = resource.fetch('title', '')

          # Special case for something like:
          # file { 'my-own-resource-name':
          #   path => '/var/lib/puppet/my-file.txt'
          # }
          #
          # The catalog-diff will treat the file above as "File\f/var/lib/puppet/my-file.txt" since the
          # name that was given to the resource has no effect on how the file is deployed.
          #
          # Note that if the file was specified like this:
          # file { '/var/lib/puppet/my-file.txt': }
          #
          # That also is "File\f/var/lib/puppet/my-file.txt" and that's what we want.
          if resource.fetch('type', '') == 'File' && resource.key?('parameters') && resource['parameters'].key?('path')
            hsh['title'] = resource['parameters']['path']
            resource['parameters'].delete('path')
          end

          # Process each attribute in the resource
          resource.each do |k, v|
            # Title was pre-processed
            next if k == 'title' || k == 'type'

            # Handle parameters
            if k == 'parameters'
              cleansed_param = cleanse_parameters_hash(v)
              hsh[k] = cleansed_param unless cleansed_param.nil? || cleansed_param.empty?
            elsif k == 'tags'
              # The order of tags is unimportant. Sort this array to avoid false diffs if order changes.
              # Also if tags is empty, don't add. Most uses of catalog diff will want to ignore tags,
              # and if you're ignoring tags you won't get here anyway. Also, don't add empty array of tags.
              unless @opts[:ignore_tags]
                hsh[k] = v.sort if v.is_a?(Array) && v.any?
              end
            elsif k == 'file' || k == 'line'
              # We don't care, for the purposes of catalog-diff, from which manifest and line this resource originated.
              # However, we may report this to the user, so we will keep it in here for now.
              hsh[k] = v
            else
              # Default case: just use the existing value as-is.
              hsh[k] = v
            end
          end

          result << hsh unless hsh.empty?
        end
        result
      end

      # Logic to match attribute regular expressions. Called by lambda function in attr_match_rule?.
      # @param operator [String] Either =~> (any regexp match) or =&> (all diffs must match regexp)
      # @param regex [Regexp] Regex object
      # @param old_val [String] Value from first catalog
      # @param new_val [String] Value from first catalog
      # @return [Boolean] True if condition is satisfied, false otherwise
      def regexp_operator_match?(operator, regex, old_val, new_val)
        # Use diffy to get only the lines that have changed in a text object.
        # As we iterate through the diff, jump out if we have our answer: either
        # true if '=~>' finds ANY match, or false if '=&>' fails to find a match.
        Diffy::Diff.new(old_val, new_val, context: 0).each do |line|
          if regex.match(line.strip)
            return true if operator == '=~>'
          elsif operator == '=&>'
            return false
          end
        end

        # At this point, we did not return out of the loop early. This means that for
        # '=~>' no matches were found at all, so we should return false. Or for '=&>'
        # every diff matched, so we should return true.
        operator == '=~>' ? false : true
      end

      # Determine whether a particular attribute matches a rule
      # @param rule [Hash] Rule
      # @param attrib [String] String representation of attribute
      # @param old_val [?] Old value
      # @param new_val [?] New value
      # @return [Boolean] True if attribute matches rule
      def attr_match_rule?(rule, attrib, old_val, new_val)
        matcher = ->(_x, _y) { true }
        rule_attr = rule[:attr].dup

        # Start with '+' or '-' indicates attribute was added or removed
        if rule_attr.start_with?('+')
          return false unless old_val.nil?
          rule_attr.sub!(/^\+/, '')
        elsif rule_attr.start_with?('-')
          return false unless new_val.nil?
          rule_attr.sub!(/^-/, '')
        end

        # Conditions that match the attribute value or regular expression
        # Operators supported include:
        #   =>   String equality
        #   =+>  Attribute must have been added and equal this
        #   =->  Attribute must have been removed and equal this
        #   =~>  Change must match regexp (one line of change matching is sufficient)
        #   =&>  Change must match regexp (all lines of change MUST match regexp)
        if rule_attr =~ /\A(.+?)(=[\-\+~&]?>)(.+)/m
          rule_attr = Regexp.last_match(1)
          operator = Regexp.last_match(2)
          value = Regexp.last_match(3)
          if operator == '=>'
            # String equality test
            matcher = ->(x, y) { x == value || y == value }
          elsif operator == '=+>'
            # String equality test only of the new value
            matcher = ->(_x, y) { y == value }
          elsif operator == '=->'
            # String equality test only of the old value
            matcher = ->(x, _y) { x == value }
          elsif operator == '=~>' || operator == '=&>'
            begin
              my_regex = Regexp.new(value, Regexp::IGNORECASE)
            rescue RegexpError => exc
              key = "#{rule[:type]}[#{rule[:title]}] #{rule_attr.gsub(/\f/, '::')} =~ #{value}"
              raise RegexpError, "Invalid ignore regexp for #{key}: #{exc.message}"
            end
            matcher = ->(x, y) { regexp_operator_match?(operator, my_regex, x, y) }
          end
        end

        if rule_attr =~ /\f/
          beginning = rule_attr.start_with?("\f") ? '\A' : '(\A|\f)'
          ending = '(\f|\Z)'
          rule_attr.gsub!(/^\f+/, '')
          hash_attr_regexp = Regexp.new(beginning + Regexp.escape(rule_attr) + ending, Regexp::IGNORECASE)
          return attrib.match(hash_attr_regexp) && matcher.call(old_val, new_val)
        else
          s = attrib.downcase.split(/\f/)
          return s.include?(rule_attr.downcase) && matcher.call(old_val, new_val)
        end
      end

      # Determine if a particular item matches a particular ignore pattern
      # @param rule [Hash] Ignore rule
      # @param diff_type [String] One of +, -, ~, !
      # @param hsh [Hash] { type: title: attr: } parsed resource name
      # @param old_val [?] Old value
      # @param new_val [?] New value
      # @return [Boolean] True if the item matched the rule
      def ignore_match?(rule_in, diff_type, hsh, old_val, new_val)
        rule = rule_in.dup

        # Type matches?
        if rule[:type].is_a?(Regexp)
          return false unless hsh[:type].match(rule[:type])
        elsif rule[:type].is_a?(String)
          return false unless rule[:type] == '*' || rule[:type].casecmp(hsh[:type]).zero?
        end

        # Title matches? (Support regexp and string)
        if rule[:title].is_a?(Regexp)
          return false unless hsh[:title].match(rule[:title])
        elsif rule[:title] != '*'
          return false unless rule[:title].casecmp(hsh[:title]).zero?
        end

        # Special 'attributes': Ignore specific diff types (+ add, - remove, ~ and ! change)
        if rule[:attr] =~ /\A[\-\+~!]+\Z/
          return ignore_match_true(hsh, rule) if rule[:attr].include?(diff_type)
          return false
        end

        # Attribute matches?
        return ignore_match_true(hsh, rule) if hsh[:attr].nil? && rule[:attr].nil?
        return ignore_match_true(hsh, rule) if rule[:attr] == '*'
        return false if hsh[:attr].nil?

        # Attributes that match values
        if rule[:attr].is_a?(Array)
          rule[:attr].each do |attrib|
            return false unless attr_match_rule?(rule.merge(attr: attrib), hsh[:attr], old_val, new_val)
          end
        else
          return false unless attr_match_rule?(rule, hsh[:attr], old_val, new_val)
        end

        # Still here? Must be true.
        ignore_match_true(hsh, rule)
      end

      # Debugging for ignore_match: This logs a debug message for an ignored diff and then returns true.
      # @param hsh [Hash] Item that is being checked
      # @param rule [Hash] Ignore rule
      # @return [Boolean] Always returns true
      def ignore_match_true(hsh, rule)
        @logger.debug "Ignoring #{hsh.inspect}, matches #{rule.inspect}"
        true
      end

      # Determine if a given item is ignored
      # @param diff [Array] Diff
      # @return [Boolean] True to ignore resource, false not to ignore
      def ignored?(diff)
        key = diff[1]
        hsh = if key =~ /\A([^\f]+)\f([^\f]+)\Z/
          { type: Regexp.last_match(1), title: Regexp.last_match(2) }
        else
          s = key.split(/\f/, 3)
          { type: s[0], title: s[1], attr: s[2] }
        end
        @ignore.each do |rule|
          return true if ignore_match?(rule, diff[0], hsh, diff[2], diff[3])
        end
        false
      end

      # Cleanse parameters of filtered attributes.
      # @param parameters_hash [Hash] Hash of parameters
      # @return [Hash] Cleaned parameters hash (original input hash is not altered)
      def cleanse_parameters_hash(parameters_hash)
        result = parameters_hash.dup

        # 'before' and 'require' handle internal Puppet ordering but do not affect what
        # happens on the target machine. Don't consider these for the purpose of catalog diff.
        result.delete('before')
        result.delete('require')

        # Sort arrays for parameters where the order is unimportant
        %w(notify subscribe tag).each { |key| result[key].sort! if result[key].is_a?(Array) }

        # Return the result
        result
      end

      # Pre-process catalog resources by looking for additions and removals. This is required to distinguish between
      # top-level addition/removal of resources, and addition/removal of elements from arrays and hashes nested within
      # resources (those too will be reported as +/- by hashdiff, but we want to see them as changes).
      # @return [Array<['+|-', Key, Hash]>, Array<(catalog1 hashes)>, Array<(catalog2 hashes)>] Data
      def preprocess_diff
        @logger.debug "Entering preprocess_diff; catalog sizes: #{@catalog1.size}, #{@catalog2.size}"

        # Do the pre-processing: filter_and_cleanup catalogs of resources that do not matter, and then run
        # through each to tokenize the entries for initial comparison.
        # NOTE: 'catalog1' and 'catalog2' are methods above that call filter_and_cleanup(@catalogX)

        catalog1_result = resources_as_hashes_with_serialized_keys(catalog1)
        catalog1_resources = catalog1_result[:catalog]

        catalog2_result = resources_as_hashes_with_serialized_keys(catalog2)
        catalog2_resources = catalog2_result[:catalog]

        # Call out all added and removed keys, and delete these from further consideration.
        # (That way, 'hashdiff' will only be used to compare keys existing in both old and new.)
        result = []
        added_keys = catalog2_resources.keys - catalog1_resources.keys
        removed_keys = catalog1_resources.keys - catalog2_resources.keys

        added_keys.each do |key|
          key_for_map = key.split(/\f/, 3)[0..1].join("\f") # Keep first two values separated by \f
          result << ['+', key, catalog2_resources[key], catalog2_result[:catalog_map][key_for_map]]
          catalog2_resources.delete(key)
        end

        removed_keys.each do |key|
          key_for_map = key.split(/\f/, 3)[0..1].join("\f") # Keep first two values separated by \f
          result << ['-', key, catalog1_resources[key], catalog1_result[:catalog_map][key_for_map]]
          catalog1_resources.delete(key)
        end

        @logger.debug "Exiting preprocess_diff; added #{added_keys.size}, removed #{removed_keys.size}"
        [result, catalog1_result, catalog2_result]
      end

      # This runs the remaining resources in the catalogs through hashdiff.
      # @param catalog1_resources [<Hash<Catalog Resources, Catalog Map>] Hash of catalog1's resources, tokenized
      # @param catalog2_resources [<Hash<Catalog Resources, Catalog Map>] Hash of catalog2's resources, tokenized
      # @return [Array<Differences>, Array<(Token, Old, New)>] Input to next step
      def hashdiff_initial(catalog1_in, catalog2_in)
        catalog1_resources = catalog1_in[:catalog]
        catalog2_resources = catalog2_in[:catalog]

        @logger.debug "Entering hashdiff_initial; catalog sizes: #{catalog1_resources.size}, #{catalog2_resources.size}"
        result = []
        hashdiff_add_remove = Set.new
        hashdiff_result = HashDiff.diff(catalog1_resources, catalog2_resources, delimiter: "\f")
        hashdiff_result.each do |obj|
          # Regular change
          if obj[0] == '~'
            key_for_map = obj[1].split(/\f/, 3)[0..1].join("\f") # Keep first two values separated by \f
            obj << catalog1_in[:catalog_map][key_for_map]
            obj << catalog2_in[:catalog_map][key_for_map]
            result << obj
            next
          end

          # Added/removed element to/from array
          if obj[1] =~ /^(.+)\[\d+\]/
            hashdiff_add_remove.add(Regexp.last_match(1))
            next
          end

          # Added a new key that points to some kind of data structure that we know how
          # to handle.
          if obj[1] =~ /^(.+)\f([^\f]+)$/ && [String, Fixnum, Float, TrueClass, FalseClass, Array, Hash].include?(obj[2].class)
            hashdiff_add_remove.add(obj[1])
            next
          end

          # Any other weird edge cases need to be added and handled here. For now just error out.
          # :nocov:
          raise "Bug (please report): Unexpected data structure in hashdiff_result: #{obj.inspect}"
          # :nocov:
        end
        @logger.debug "Exiting hashdiff_initial; changes: #{result.size}, nested changes: #{hashdiff_add_remove.size}"
        [result, hashdiff_add_remove.to_a]
      end

      # This diffs nested changes deep in the data structure. Each item in hashdiff_add_remove
      # has been previously identified as being an addition or removal from a deeply nested element
      # that exists in both old and new. This code compares that deeply nested element in both the
      # old and new, and uses status '!' (rather than '+', '-', or '~') to indicate that the change
      # occurred in a deeply nested element.
      # @param hashdiff_add_remove [Array<Serialized Tokens>] Adds/removes from hashdiff
      # @param remaining1 [Hash<Catalog1 Resources>] Serialized key / value pairs for catalog1 resources
      # @param remaining2 [Hash<Catalog1 Resources>] Serialized key / value pairs for catalog2 resources
      # @return [Array<'!', key, old, new>] Change set
      def hashdiff_nested_changes(hashdiff_add_remove, remaining1, remaining2)
        return [] if hashdiff_add_remove.empty?

        catalog1 = remaining1[:catalog]
        catalog2 = remaining2[:catalog]
        catmap1 = remaining1[:catalog_map]
        catmap2 = remaining2[:catalog_map]
        result = []

        hashdiff_add_remove.each do |key|
          key_split = key.split(/\f/)
          first_part_of_key = [key_split.shift, key_split.shift].join("\f")
          key_split.unshift first_part_of_key
          if catalog1[first_part_of_key].is_a?(Hash) && catalog2[first_part_of_key].is_a?(Hash)
            # At this point catalog1[first_part_of_key] might look like this:
            #   {
            #     "type"=>"Class",
            #     "title"=>"Openssl::Package",
            #     "exported"=>false,
            #     "parameters"=>{"openssl_version"=>"1.0.1-4", "common-array"=>[1, 3, 5]}
            #   }
            # and key_split looks like this:
            #   [ "Class\fOpenssl::Package", 'parameters', 'common-array' ]
            #
            # We have to dig out remaining1["Class\fOpenssl::Package"]['parameters']['common-array']
            # to do the comparison.
            obj0 = dig_out_key(catalog1, key_split.dup)
            obj1 = dig_out_key(catalog2, key_split.dup)
            result << ['!', key, obj0, obj1, catmap1[first_part_of_key], catmap2[first_part_of_key]]
          else
            # Bug condition
            # :nocov:
            raise "BUG (Please report): Unexpected resource: #{first_part_of_key.inspect} not a catalog resource"
            # :nocov:
          end
        end
        result
      end

      # From an array of keys [key1, key2, key3, ...] dig out the value of hash[key1][key2][key3]...
      # @param hash_in [Hash] Starting hash (or value passed in by recursion)
      # @param key_array [Array<String>] Names of keys in order
      # @return [?] Value of hash_in[key1][key2][key3]..., or nil if any keys along the way don't exist
      def dig_out_key(hash_in, key_array)
        return hash_in if key_array.empty?
        return hash_in unless hash_in.is_a?(Hash)
        return nil unless hash_in.key?(key_array[0])
        next_key = key_array.shift
        dig_out_key(hash_in[next_key], key_array)
      end

      # This is a helper for the constructor, verifying that the incoming catalog is an expected
      # object.
      # @param catalog [OctocatalogDiff::Catalog] Incoming catalog
      # @return [Hash] Internal simplified hash object
      def catalog_resources(catalog_in, name = 'Passed catalog')
        return catalog_in.resources if catalog_in.is_a?(OctocatalogDiff::Catalog)
        raise OctocatalogDiff::Errors::DifferError, "#{name} is not a valid catalog (input datatype: #{catalog_in.class})"
      end

      # Turn array of resources into a hash by serialized keys. For consistency with 'hashdiff'
      # the serialized key is the resource type and all components of the title (split on '::'),
      # joined with \f.
      # @param catalog Array<Hash> Resource array from catalog
      # @return [Hash] See description above
      def resources_as_hashes_with_serialized_keys(catalog)
        result = {
          catalog: {},
          catalog_map: {}
        }
        catalog.each do |item|
          i = item.dup
          result[:catalog_map]["#{item['type']}\f#{item['title']}"] = { 'file' => item['file'], 'line' => item['line'] }
          i.delete('file')
          i.delete('line')
          result[:catalog]["#{item['type']}\f#{item['title']}"] = i
        end
        result
      end
    end
  end
end
