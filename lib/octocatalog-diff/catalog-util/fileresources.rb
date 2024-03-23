# frozen_string_literal: true

require 'digest'

module OctocatalogDiff
  module CatalogUtil
    # Used to convert file resources such as:
    #   file { 'something': source => 'puppet:///modules/xxx/yyy'}
    # to:
    #   file { 'something': content => $( cat modules/xxx/files/yyy )}
    # This allows the displayed diff to show differences in static files.
    class FileResources
      # Public method: Convert file resources to text. See the description of the class
      # just above for details.
      # @param obj [OctocatalogDiff::Catalog] Catalog object (will be modified)
      # @param environment [String] Environment (defaults to production)
      def self.convert_file_resources(obj, environment = 'production')
        return unless obj.valid? && obj.compilation_dir.is_a?(String) && !obj.compilation_dir.empty?
        _convert_file_resources(
          obj.resources,
          obj.compilation_dir,
          environment,
          obj.options[:compare_file_text_ignore_tags],
          should_raise_notfound?(obj)
        )
        begin
          obj.catalog_json = ::JSON.generate(obj.catalog)
        rescue ::JSON::GeneratorError => exc
          obj.error_message = "Failed to generate JSON: #{exc.message}"
        end
      end

      # Internal method: Based on parameters, determine whether a "not found" for a file that fails
      # to be located should result in an exception.
      # @param obj [OctocatalogDiff::Catalog] Catalog object
      # @return [Bool] Whether to raise if not found
      def self.should_raise_notfound?(obj)
        return true if obj.options[:compare_file_text] == :force
        return false if obj.options[:compare_file_text] == :soft
        obj.options[:tag] != 'from'
      end

      # Internal method: Locate a file that is referenced at puppet:///modules/xxx/yyy using the
      # module path that is specified within the environment.conf file (assuming the default 'modules'
      # directory doesn't exist or the module isn't found in there). If the file can't be found then
      # this returns nil which may trigger an error.
      # @param src_in [String|Array] A file reference: puppet:///modules/xxx/yyy
      # @param modulepaths [Array] Cached module path
      # @return [String] File system path to referenced file
      def self.file_path(src_in, modulepaths)
        valid_sources = [src_in].flatten.select { |line| line =~ %r{\Apuppet:///modules/([^/]+)/(.+)} }
        return unless valid_sources.any?

        valid_sources.each do |src|
          src =~ %r{\Apuppet:///modules/([^/]+)/(.+)}
          path = File.join(Regexp.last_match(1), 'files', Regexp.last_match(2))
          modulepaths.each do |mp|
            file = File.join(mp, path)
            return file if File.exist?(file)
          end
        end

        nil
      end

      # Internal method: Parse environment.conf to find the modulepath
      # @param dir [String] Directory in which to look for environment.conf
      # @return [Array] Module paths
      def self.module_path(dir)
        environment_conf = File.join(dir, 'environment.conf')
        return [File.join(dir, 'modules')] unless File.file?(environment_conf)

        # This doesn't support multi-line, continuations with backslash, etc.
        # Does it need to??
        if File.read(environment_conf) =~ /^modulepath\s*=\s*(.+)/
          result = []
          Regexp.last_match(1).split(/:/).map(&:strip).each do |path|
            next if path.start_with?('$')
            result.concat(Dir.glob(File.expand_path(path, dir)))
          end
          result
        else
          [File.join(dir, 'modules')]
        end
      end

      # Internal method: Static method to convert file resources. The compilation directory is
      # required, or else this is a no-op. The passed-in array of resources is modified by this method.
      # @param resources [Array<Hash>] Array of catalog resources
      # @param compilation_dir [String] Compilation directory
      # @param environment [String] Environment
      # @param ignore_tags [Array<String>] Tags that exempt a resource from conversion
      # @param raise_notfound [Bool] Whether to raise if a file could not be found
      def self._convert_file_resources(resources, compilation_dir, environment, ignore_tags, raise_notfound)
        # Calculate compilation directory. There is not explicit error checking here because
        # there is on-demand, explicit error checking for each file within the modification loop.
        return unless compilation_dir.is_a?(String) && compilation_dir != ''

        # Making sure that compilation_dir/environments/<env>/modules exists (and by inference,
        # that compilation_dir/environments/<env> is pointing at the right place). Otherwise, try to find
        # compilation_dir/modules. If neither of those exist, this code can't run.
        env_dir = File.join(compilation_dir, 'environments', environment)
        modulepaths = module_path(env_dir) + module_path(compilation_dir)
        modulepaths.select! { |x| File.directory?(x) }
        return if modulepaths.empty?

        # At least one existing module path was found! Run the code to modify the resources.
        resources.map! do |resource|
          if resource_convertible?(resource)
            path = file_path(resource['parameters']['source'], modulepaths)

            if resource['tags'] && ignore_tags && (resource['tags'] & ignore_tags).any?
              # Resource tagged not to be converted -- do nothing.
            elsif path && File.file?(path)
              # If the file is found, read its content. If the content is all ASCII, substitute it into
              # the 'content' parameter for easier comparison. If not, instead populate the md5sum.
              # Delete the 'source' attribute as well.
              content = File.read(path)
              is_ascii = content.force_encoding('UTF-8').ascii_only?
              resource['parameters']['content'] = is_ascii ? content : '{md5}' + Digest::MD5.hexdigest(content)
              resource['parameters'].delete('source')
            elsif path && File.exist?(path)
              # We are not handling recursive file installs from a directory or anything else.
              # However, the fact that we found *something* at this location indicates that the catalog
              # is probably correct. Hence, the very general .exist? check.
            elsif !raise_notfound
              # Don't raise an exception for an invalid source in the "from"
              # catalog, because the developer may be fixing this in the "to"
              # catalog. If it's broken in the "to" catalog as well, the
              # exception will be raised when this code runs on that catalog.
            else
              # Pass this through as a wrapped exception, because it's more likely to be something wrong
              # in the catalog itself than it is to be a broken setup of octocatalog-diff.
              #
              # Example error: <OctocatalogDiff::Errors::CatalogError: Unable to resolve
              # source=>'puppet:///modules/test/tmp/bar' in File[/tmp/bar]
              # (/x/modules/test/manifests/init.pp:46)>
              source = resource['parameters']['source']
              type = resource['type']
              title = resource['title']
              file = resource['file'].sub(Regexp.new('^' + Regexp.escape(env_dir) + '/'), '')
              line = resource['line']
              message = "Unable to resolve source=>'#{source}' in #{type}[#{title}] (#{file}:#{line})"
              raise OctocatalogDiff::Errors::CatalogError, message
            end
          end

          resource
        end
      end

      # Internal method: Determine if a resource is convertible. It is convertible if it
      # is a file resource with no declared 'content' and with a declared and parseable 'source'.
      # It is not convertible if the resource is tagged with one of the tags declared by
      # the option `--compare-file-text-ignore-tags`.
      # @param resource [Hash] Resource to check
      # @return [Boolean] True of resource is convertible, false if not
      def self.resource_convertible?(resource)
        return true if resource['type'] == 'File' && \
                       !resource['parameters'].nil? && \
                       resource['parameters'].key?('source') && \
                       !resource['parameters'].key?('content') && \
                       valid_sources?(resource)

        false
      end

      def self.valid_sources?(resource)
        [resource['parameters']['source']].flatten.select { |line| line =~ %r{\Apuppet:///modules/([^/]+)/(.+)} }.any?
      end
    end
  end
end
