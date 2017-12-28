require "ass_ole/app_extension/version"

module AssOle
  require 'ass_ole/snippets/shared'
  module AppExtension
    require 'ass_ole'

    module Abstract
      # @note Docs for
      #  mixin
      #  {http://www.rubydoc.info/gems/ass_ole-snippets-shared/AssOle/Snippets/Shared/AppCompatibility AssOle::Snippets::Shared::AppCompatibility}
      #
      # Class parent for all extensions. Define your own class and
      # override methods from {Extension::AbstractMethods}
      # @example
      #  class FooExtension < AssOle::AppExtension::Abstract::Extension
      #
      #   def path
      #     File.expand_path '../foo_extension.cfe', __FILE__
      #   end
      #
      #   # Override abstract method
      #   # must returns WIN32OLE object(1C extension BinaryData)'
      #   def data
      #     newObject('BinaryData', real_win_path(path))
      #   end
      #
      #   # Override abstract method
      #   # must returns `Gem::Requirement` 1C platform version requirement
      #   def platform_require
      #     Gem::Requirement.new '~> 8.3.10'
      #   end
      #
      #   # Override abstract method
      #   # must returns `Hash` :1c_app_name => (Gem::Requirement|String '~> 1.2.4')
      #   # or nil for independent extension
      #   def app_requirements
      #     {Accounting: '~> 3.0.56',
      #      AccountingCorp: '~> 3.0.56'}
      #   end
      #
      #   # Override abstract method
      #   # must returns extension name
      #   def name
      #     'FooExtension'
      #   end
      #  end
      # @abstract
      class Extension
        include AssOle::Snippets::Shared::AppCompatibility

        # @abstract
        module AbstractMethods
          # Define extension binary data.
          # @example
          #   def path
          #     File.expand_path '../extension.cfe', __FILE__
          #   end
          #
          #   def data
          #     newObject('BinaryData', real_win_path(path))
          #   end
          # @abstract
          # @return [WIN32OLE] object(1C extension BinaryData)
          def data
            fail 'Abstract method must returns WIN32OLE object(1C extension BinaryData)'
          end

          # Define platform version requirement
          # @example
          #   def platform_require
          #     Gem::Requirement.new '~> 8.3.8'
          #   end
          # @abstract
          # @return [Gem::Requirement]
          def platform_require
            fail 'Abstract method must returns `Gem::Requirement`'
          end

          # Define infobase configuration requirement
          # @example
          #   def app_requirements
          #     {Accounting: '~> 3.0.56', AccountingCorp: '~> 3.0.56'}
          #   end
          # @abstract
          # @return [Hash{:1c_app_name => Gem::Requirement,String} nil]
          #  +nil+ for independent extension
          def app_requirements
            fail "Abstract method must returns `Hash`"\
              " :1c_app_name => (`Gem::Requirement`|String '~> 1.2.4')"\
              " or nil for independent extension"
          end

          # Define extension name. Must match with extension metadata name!
          # @abstract
          # @return [String] extension name
          def name
            fail 'Abstract method must returns extension name'
          end
        end

        include AbstractMethods

        # see +ole_runtime+ of {#initialize}
        attr_reader :ole_runtime

        # see +safe_mode+ of {#initialize}
        attr_reader :safe_mode

        # @param ole_runtime [AssOle::Runtimes::App] 1C ole runtime
        # @param safe_mode [true false nil String] define of safe mode for
        #  an extension. For more info see 1C docomentation for +SafeMode+
        #  property of +ConfigurationExtension+ object
        def initialize(ole_runtime, safe_mode = nil)
          @ole_runtime = ole_runtime
          @safe_mode = safe_mode
        end

        # Plug extension. Do nothing if extension already plugged!
        # @return [self]
        # @raise (see can_apply?)
        # @raise (see #verify!)
        def plug
          return if plugged?
          verify!
          can_apply? && unsafe_mode_set.Write(data)
          self
        end
        alias_method :write, :plug

        # Force plug without check {#plugged?}, {#verify!} and {#can_apply?}
        # @return [self]
        def plug!
          unsafe_mode_set.Write(data)
          self
        end
        alias_method :write!, :plug!

        # Unplug extension. Do nothing unless extension plugged.
        # @return [self]
        def unplug!
          return unless exist?
          ole.Delete
          self
        end
        alias_method :delete!, :unplug!

        def unsafe_mode_get
          r = newObject('UnsafeOperationProtectionDescription')
          r.UnsafeOperationWarnings = false
          r
        end
        private :unsafe_mode_get

        def unsafe_mode_set
          if ole.ole_respond_to? :UnsafeActionProtection
            ole.UnsafeActionProtection = unsafe_mode_get
          end

          if ole.ole_respond_to? :SafeMode
            ole.SafeMode = safe_mode unless safe_mode.nil?
          end
          ole
        end
        private :unsafe_mode_set

        # Critical +ConfigurationExtensionApplicationIssueInformation+.
        # If you have such problems, extension will not be connected.
        # @return [Array<WIN32OLE>]
        #  +ConfigurationExtensionApplicationIssueInformation+
        def apply_errors
          apply_errors_get(data)
        end

        # Not critical +ConfigurationExtensionApplicationIssueInformation+.
        # If you have such problems, extension will be connected.
        # @return (see #apply_errors)
        def apply_warnings
          apply_problems_get(data).select do |problem|
            (sTring(problem.Severity) =~ %r{(Критичная|Critical)}).nil?
          end
        end

        def apply_problems_get(ext_data)
          r = []
          ole.CheckCanApply(ext_data, false).each do |problem|
            r << problem
          end
          r
        end
        private :apply_problems_get

        def apply_errors_get(ext_data)
          apply_problems_get(ext_data).select do |problem|
            sTring(problem.Severity) =~ %r{(Критичная|Critical)}
          end
        end
        private :apply_problems_get

        # Checks the possibility plugging extension
        # @raise [RuntimeError] if {#apply_errors} isn't empty
        def can_apply?
          errors = apply_errors
          fail "Extension can't be applied:\n"\
            " - #{errors.map(&:Description).join(' - ')} " if\
            errors.size > 0
          true
        end

        # Return +true+ if extension stored in infobase
        def exist?
          !find_exists.nil?
        end

        # Return +true+ if extension {#exists?} and stored data can be applyed
        # without errors
        def plugged?
          exist? && apply_errors_get(ole.GetData).size > 0
        end

        def find_exists
          r = all_extensions.select {|ext| ext.Name =~ /^#{name}$/i}
          fail "Too many #{r.size} extension `#{name}` found" if r.size > 1
          r[0]
        end
        private :find_exists

        def manager
          configurationExtensions
        end
        private :manager

        # Array of all application extensions.
        # @return [Array<WIN32OLE>] +ConfigurationExtension+
        def all_extensions
          r = []
          manager.Get.each do |ext|
            r << ext
          end
          r
        end

        def ole_get
          return find_exists if exist?
          manager.Create
        end
        private :ole_get

        # Extension ole object.
        # @return [WIN32OLE] +ConfigurationExtension+
        def ole
          @ole ||= ole_get
        end

        # @return 1C ole connector
        def ole_connector
          ole_runtime.ole_connector
        end

        # @raise [RuntimeError] if extension is incompatible
        def verify!
          verify_version_compatibility!
          verify_application!
        end

        # @return [String] application configuration name +metaData.Name+
        def app_name
          metaData.Name
        end

        # @return [Gem::Version]
        #  application configuration version +metaData.Version+
        def app_version
          Gem::Version.new(metaData.Version)
        end

        # @api private
        def verify_version_compatibility!
          fail ArgumentError, "Require application compatibility "\
            "`#{platform_require}`. Got application compatibility version"\
            " `#{app_compatibility_version}`" unless\
            platform_require.satisfied_by? app_compatibility_version
        end

        # @api private
        def verify_application!
          return unless app_requirements

          req = app_requirements[app_name]

          fail "Unsupported application `#{app_name}`. Supported: "\
            " - #{app_requirements.keys.join(' - ')}" unless req

          fail "Unsupported application version `#{app_version}`. Require"\
            " version #{req}" unless\
            Gem::Requirement.new.satisfied_by? app_version
        end

        # Save actual stored extension data to file
        # @param dir [String] directory where file will be writed
        # @return [String] file name
        def save_stored_data(dir)
          file = File.join(dir, "#{name}.#{Gem::Version.new(ole.Version)}.cfu")
          ole.GetData.Write(real_win_path(file))
          file
        end
      end
    end

    # Class for explore exists infobase extensions.
    class Spy < Abstract::Extension
      def initialize(ole_runtime, ole)
        @ole_runtime = ole_runtime
        @ole = ole
      end

      def ole_get
        @ole
      end
      private :ole_get

      # (see Abstract::Extension)
      def ole
        @ole
      end

      # Do nothing.
      # @return [self]
      def plug!
        self
      end

      # Do nothing
      # @return [self]
      def unplug!
        self
      end

      # Do nothing
      # @return [self]
      def verify!
        self
      end

      # Return {#ole} +Name+ property
      # @return [String]
      def name
        ole.Name
      end

      # Return {#ole} +GetData+
      # @return [WIN32OLE] stored +BinaryData+
      def data
        ole.GetData
      end

      # @return ['~> 0'] permanent
      def platform_require
        Gem::Requirement.new '~> 0'
      end

      # @return [nil] permanent
      def app_requirements
        nil
      end

      # Do nothing.
      # @return {#ole}
      def unsafe_mode_set
        ole
      end
      private :unsafe_mode_set
    end

    # @api private
    module Plug
      attr_reader :info_base

      # @api private
      # @param info_base [AssMaintainer::InfoBase] instance
      def initialize(info_base)
        @info_base = info_base
        ole_runtime_get.run info_base
      end

      # Make new +ext_klass+ plugged instance
      # @api private
      # @param safe_mode (see #new_ext)
      # @param ext_klass (see #new_ext)
      # @return (see Abstract::Extension#plug)
      def exec(ext_klass, safe_mode)
        new_ext(ext_klass, safe_mode).plug
      end

      # Make new +ext_klass+ instance
      # @api private
      # @param safe_mode
      #  (see AssOle::AppExtension::Abstract::Extension#initialize)
      # @param ext_klass [Class] childe of
      #  {AssOle::AppExtension::Abstract::Extension}
      # @return [ext_klass] instance
      def new_ext(ext_klass, safe_mode)
        ext_klass.new(self, safe_mode)
      end

      # @api private
      def self.external_runtime_get
        Module.new do
          is_ole_runtime :external
        end
      end

      # @param info_base (see Plug#initialize)
      def self.new(info_base)
        inst = Class.new do
          like_ole_runtime Plug.external_runtime_get
          include Plug
        end.new(info_base)
        yield inst if block_given?
        inst
      end
    end

    # Plug extension to +info_base+
    # @param info_base (see Plug#initialize)
    # @param ext_klass (see Plug#exec)
    # @param safe_mode (see Plug#exec)
    # @return (see Plug#exec)
    def self.plug(info_base, ext_klass, safe_mode = true)
      Plug.new(info_base).exec(ext_klass, safe_mode)
    end

    # Returns all extensions stored in +info_base+
    # @return [Array<Spy>]
    def self.all_extensions(info_base)
      spy = Plug.new_ext(info_base, Spy, nil)
      spy.all_extensions.map do |ole|
        Spy.new(spy.ole_runtime, ole)
      end
    end
  end
end
