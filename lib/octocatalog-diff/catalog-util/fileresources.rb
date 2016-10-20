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
      def self.convert_file_resources(obj)
        return unless obj.valid? && obj.compilation_dir.is_a?(String) && !obj.compilation_dir.empty?
        _convert_file_resources(obj.resources, obj.compilation_dir)
        begin
          obj.catalog_json = ::JSON.generate(obj.catalog)
        rescue ::JSON::GeneratorError => exc
          obj.error_message = "Failed to generate JSON: #{exc.message}"
        end
      end

      # Internal method: Static method to convert file resources. The compilation directory is
      # required, or else this is a no-op. The passed-in array of resources is modified by this method.
      # @param resources [Array<Hash>] Array of catalog resources
      # @param compilation_dir [String] Compilation directory (so files can be looked up)
      def self._convert_file_resources(resources, compilation_dir)
        # Calculate compilation directory. There is not explicit error checking here because
        # there is on-demand, explicit error checking for each file within the modification loop.
        return unless compilation_dir.is_a?(String) && compilation_dir != ''

        # Making sure that compilation_dir/environments/production/modules exists (and by inference,
        # that compilation_dir/environments/production is pointing at the right place). Otherwise, try to find
        # compilation_dir/modules. If neither of those exist, this code can't run.
        env_dir = File.join(compilation_dir, 'environments', 'production')
        unless File.directory?(File.join(env_dir, 'modules'))
          return unless File.directory?(File.join(compilation_dir, 'modules'))
          env_dir = compilation_dir
        end

        # Modify the resources
        resources.map! do |resource|
          if resource_convertible?(resource)
            # Parse the 'source' parameter into a file on disk
            src = resource['parameters']['source']
            raise "Bad parameter source #{src}" unless src =~ %r{^puppet:///modules/([^/]+)/(.+)}
            path = File.join(env_dir, 'modules', Regexp.last_match(1), 'files', Regexp.last_match(2))

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
              raise Errno::ENOENT, "Unable to find '#{src}' at #{path}!"
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
                       resource['parameters'].key?('source') && \
                       !resource['parameters'].key?('content') && \
                       resource['parameters']['source'] =~ %r{^puppet:///modules/([^/]+)/(.+)}
        false
      end
    end
  end
end
