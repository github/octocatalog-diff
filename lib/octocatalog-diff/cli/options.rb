# frozen_string_literal: true

require_relative '../cli'
require_relative '../facts'
require_relative '../version'

require 'optparse'

module OctocatalogDiff
  class Cli
    # This class contains the option parser. 'parse_options' is the external entry point.
    class Options
      # The usage banner.
      BANNER = 'Usage: catalog-diff -n <hostname> [-f <from environment>] [-t <to environment>]'.freeze

      # List of classes
      def self.classes
        @classes ||= []
      end

      # Define the Option class and newoption() method for use by cli/options/*.rb files
      class Option
        DEFAULT_WEIGHT = 999
        def self.has_weight(w) # rubocop:disable Style/PredicateName
          @weight = w
        end

        def self.weight
          @weight || DEFAULT_WEIGHT
        end

        def self.name
          self::NAME
        end

        def self.newoption(name, &block)
          klass = Class.new(OctocatalogDiff::Cli::Options::Option)
          klass.const_set('NAME', name)
          klass.class_exec(&block)
          Options.classes.push(klass)
        end
      end

      # Method to call all of the other methods in this class. Except in very specific circumstances,
      # this should be the method called from outside of this class.
      # @param argv [Array] Array of command line arguments
      # @param defaults [Hash] Default values
      # @return [Hash] Parsed options
      def self.parse_options(argv, defaults = {})
        options = defaults.dup
        Options.classes.clear
        ::OptionParser.new do |parser|
          parser.banner = "#{BANNER}\n\n"
          option_classes.each do |klass|
            obj = klass.new
            obj.parse(parser, options)
          end
          parser.on_tail('-v', '--version', 'Show version information about this program and quit.') do
            puts "octocatalog-diff #{OctocatalogDiff::Version::VERSION}"
            exit
          end
        end.parse! argv
        options
      end

      # Read in *.rb files in the 'options' directory and create classes from them.
      # Sort the classes according to weight and name and return the list of sorted classes.
      # @return [Array<Class>] Sorted classes
      def self.option_classes
        files = Dir.glob(File.join(File.dirname(__FILE__), 'options', '*.rb'))
        files.each { |file| load file } # Populates self.classes
        classes.sort do |a, b|
          [
            a.weight <=> b.weight,
            a.name.downcase <=> b.name.downcase,
            a.object_id <=> b.object_id
          ].find(&:nonzero?)
        end
      end

      # Sets up options that can be defined globally or for just one branch. For example, with a
      # CLI name of 'puppet-binary' this will acknowledge 3 options: --puppet-binary (global),
      # --from-puppet-binary (for the from branch only), and --to-puppet-binary (for the to branch
      # only). The only options that will be created are the 'to' and 'from' variants, but the global
      # option will populate any of the 'to' and 'from' variants that are missing.
      # @param :datatype [?] Expected data type
      def self.option_globally_or_per_branch(opts = {})
        datatype = opts.fetch(:datatype, '')
        return option_globally_or_per_branch_string(opts) if datatype.is_a?(String)
        return option_globally_or_per_branch_array(opts) if datatype.is_a?(Array)
        raise ArgumentError, "option_globally_or_per_branch not equipped to handle #{datatype.class}"
      end

      # See description of `option_globally_or_per_branch`. This implements the logic for a string value.
      # @param :parser [OptionParser object] The OptionParser argument
      # @param :options [Hash] Options hash being constructed; this is modified in this method.
      # @param :cli_name [String] Name of option on command line (e.g. puppet-binary)
      # @param :option_name [Symbol] Name of option in the options hash (e.g. :puppet_binary)
      # @param :desc [String] Description of option on the command line; will have "for the XX branch" appended
      def self.option_globally_or_per_branch_string(opts)
        parser = opts.fetch(:parser)
        options = opts.fetch(:options)
        cli_name = opts.fetch(:cli_name)
        option_name = opts.fetch(:option_name)
        desc = opts.fetch(:desc)

        flag = "#{cli_name} STRING"
        from_option = "from_#{option_name}".to_sym
        to_option = "to_#{option_name}".to_sym
        parser.on("--#{flag}", "#{desc} globally") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          translated = translate_option(opts[:translator], x)
          options[to_option] ||= translated
          options[from_option] ||= translated
        end
        parser.on("--to-#{flag}", "#{desc} for the to branch") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          options[to_option] = translate_option(opts[:translator], x)
        end
        parser.on("--from-#{flag}", "#{desc} for the from branch") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          options[from_option] = translate_option(opts[:translator], x)
        end
      end

      # See description of `option_globally_or_per_branch`. This implements the logic for an array.
      # @param :parser [OptionParser object] The OptionParser argument
      # @param :options [Hash] Options hash being constructed; this is modified in this method.
      # @param :cli_name [String] Name of option on command line (e.g. puppet-binary)
      # @param :option_name [Symbol] Name of option in the options hash (e.g. :puppet_binary)
      # @param :desc [String] Description of option on the command line; will have "for the XX branch" appended
      def self.option_globally_or_per_branch_array(opts = {})
        parser = opts.fetch(:parser)
        options = opts.fetch(:options)
        cli_name = opts.fetch(:cli_name)
        option_name = opts.fetch(:option_name)
        desc = opts.fetch(:desc)

        flag = "#{cli_name} STRING1[,STRING2[,...]]"
        from_option = "from_#{option_name}".to_sym
        to_option = "to_#{option_name}".to_sym
        parser.on("--#{flag}", Array, "#{desc} globally") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          translated = translate_option(opts[:translator], x)
          options[to_option] ||= []
          options[to_option].concat translated
          options[from_option] ||= []
          options[from_option].concat translated
        end
        parser.on("--to-#{flag}", Array, "#{desc} for the to branch") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          options[to_option] ||= []
          options[to_option].concat translate_option(opts[:translator], x)
        end
        parser.on("--from-#{flag}", Array, "#{desc} for the from branch") do |x|
          validate_option(opts[:validator], x) if opts[:validator]
          options[from_option] ||= []
          options[from_option].concat translate_option(opts[:translator], x)
        end
      end

      # If a validator was provided, run the validator on the supplied value. The validator is expected to
      # throw an error if there is a problem. Note that the validator runs *before* the translator if both
      # a validator and translator are supplied.
      # @param validator [Code] Validation function
      # @param value [?] Value to validate (typically a String but can really be anything)
      def self.validate_option(validator, value)
        validator.call(value)
      end

      # If a translator was provided, run the translator on the supplied value. The translator is expected
      # to return the data type needed for the option (typically a String but can really be anything). Note
      # that the translator runs *after* the validator if both a validator and translator are supplied.
      # @param translator [Code] Translator function
      # @param value [?] Original input value
      # @return [?] Translated value
      def self.translate_option(translator, value)
        return value if translator.nil?
        translator.call(value)
      end
    end
  end
end
