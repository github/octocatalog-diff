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
      def self.convert_file_resources(obj, environment = 'production')
        return unless obj.valid? && obj.compilation_dir.is_a?(String) && !obj.compilation_dir.empty?
        _convert_file_resources(obj.resources, obj.compilation_dir, environment)
        begin
          obj.catalog_json = ::JSON.generate(obj.catalog)
        rescue ::JSON::GeneratorError => exc
          obj.error_message = "Failed to generate JSON: #{exc.message}"
        end
      end

      # Internal method: Locate a file that is referenced at puppet:///modules/xxx/yyy using the
      # module path that is specified within the environment.conf file (assuming the default 'modules'
      # directory doesn't exist or the module isn't found in there). If the file can't be found then
      # this returns nil which may trigger an error.
      # @param src [String] A file reference: puppet:///modules/xxx/yyy
      # @param modulepaths [Array] Cached module path
      # @return [String] File system path to referenced file
      def self.file_path(src, modulepaths)
        unless src =~ %r{^puppet:///modules/([^/]+)/(.+)}
          raise ArgumentError, "Bad parameter source #{src}"
        end

        path = File.join(Regexp.last_match(1), 'files', Regexp.last_match(2))
        modulepaths.each do |mp|
          file = File.join(mp, path)
          return file if File.exist?(file)
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
            result << File.expand_path(path, dir)
          end
          result
        else
          [File.join(dir, 'modules')]
        end
      end

      # Internal method: Static method to convert file resources. The compilation directory is
      # required, or else this is a no-op. The passed-in array of resources is modified by this method.
      # @param resources [Array<Hash>] Array of catalog resources
      # @param compilation_dir [String] Compilation directory (so files can be looked up)
      def self._convert_file_resources(resources, compilation_dir, environment = 'production')
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
            if path.nil?
              # Pass this through as a wrapped exception, because it's more likely to be something wrong
              # in the catalog itself than it is to be a broken setup of octocatalog-diff.
              message = "Errno::ENOENT: Unable to resolve '#{resource['parameters']['source']}'!"
              raise OctocatalogDiff::Errors::CatalogError, message
            end

            if File.file?(path)
              # If the file is found, read its content. If the content is all ASCII, substitute it into
              # the 'content' parameter for easier comparison. If not, instead populate the md5sum.
              # Delete the 'source' attribute as well.
              content = File.read(path)
              is_ascii = content.force_encoding('UTF-8').ascii_only?
              resource['parameters']['content'] = is_ascii ? content : '{md5}' + Digest::MD5.hexdigest(content)
              resource['parameters'].delete('source')
            elsif File.exist?(path)
              # We are not handling recursive file installs from a directory or anything else.
              # However, the fact that we found *something* at this location indicates that the catalog
              # is probably correct. Hence, the very general .exist? check.
            else
              # This is probably a bug
              # :nocov:
              raise "Unable to find '#{resource['parameters']['source']}' at #{path}!"
              # :nocov:
            end
          end
          resource
        end
      end

      # Internal method: Determine if a resource is convertible. It is convertible if it
      # is a file resource with no declared 'content' and with a declared and parseable 'source'.
      # @param resource [Hash] Resource to check
      # @return [Boolean] True of resource is convertible, false if not
      def self.resource_convertible?(resource)
        return true if resource['type'] == 'File' && \
                       !resource['parameters'].nil? && \
                       resource['parameters'].key?('source') && \
                       !resource['parameters'].key?('content') && \
                       resource['parameters']['source'] =~ %r{^puppet:///modules/([^/]+)/(.+)}
        false
      end
    end
  end
end
