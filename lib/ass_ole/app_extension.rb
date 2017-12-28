require "ass_ole/app_extension/version"

module AssOle
  require 'ass_ole/snippets/shared'
  module AppExtension
    require 'ass_ole'

    module Abstract
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
      #   # must retus WIN32OLE object(1C extension BinaryData)'
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

        module AbstractMethods
          def data
            fail 'Abstract method must retus WIN32OLE object(1C extension BinaryData)'
          end

          def platform_require
            fail 'Abstract method must returns `Gem::Requirement`'
          end

          def app_requirements
            fail "Abstract method must returns `Hash`"\
              " :1c_app_name => (`Gem::Requirement`|String '~> 1.2.4')"\
              " or nil for independent extension"
          end

          def name
            fail 'Abstract method must returns extension name'
          end
        end

        include AbstractMethods

        attr_reader :ole_runtime, :safe_mode

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
        # @raise [RuntimeError] if extension is incompatible
        # @raise [WIN32OLERuntimeError] if extension is incompatible
        def plug
          return if exist?
          verify!
          can_apply? && unsafe_mode_set.Write(data)
          self
        end
        alias_method :write, :plug

        # Force plug withowt Ruby verifications
        # @raise [WIN32OLERuntimeError] if extension is incompatible
        # @return [self]
        def plug!
          unsafe_mode_set.Write(data)
          self
        end
        alias_method :write!, :plug!

        # Unmpug extension. Do nothing unless extension plugged.
        # @return [self]
        def unplug
          return unless exist?
          ole.Delete
          self
        end
        alias_method :delete, :unplug

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

        def apply_errors
          apply_problems.select do |problem|
            sTring(problem.Severity) =~ %r{(Критичная|Critical)}
          end
        end

        def apply_warnings
          apply_problems.select do |problem|
            (sTring(problem.Severity) =~ %r{(Критичная|Critical)}).nil?
          end
        end

        def apply_problems
          r = []
          ole.CheckCanApply(data, false).each do |problem|
            r << problem
          end
          r
        end

        def can_apply?
          apply_errors = apply_errors
          fail "Extension can't be applied:\n"\
            " - #{apply_errors.map(&:Description).join(' - ')} " if\
            apply_errors.size > 0
          true
        end

        def exist?
          !find_exists.nil?
        end
        alias_method :plugged?, :exist?

        def find_exists
          r = all_extensions.select {|ext| ext.Name =~ /^#{name}$/i}
          fail "Too many #{r.size} extension `#{name}` found" if r.size > 1
          r[0]
        end
        private :find_exists

        def manager
          configurationExtensions
        end

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

        def ole
          @ole ||= ole_get
        end

        def ole_connector
          ole_runtime.ole_connector
        end

        def verify!
          verify_version_compatibility!
          verify_application!
        end

        def app_name
          metaData.Name
        end

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
      end
    end

    # @api private
    module Plug
      attr_reader :info_base

      # @param info_base [AssMaintainer::InfoBase] instance
      def initialize(info_base)
        @info_base = info_base
        ole_runtime_get.run info_base
      end

      # @param safe_mode
      #  (see # AssOle::AppExtension::Abstract::Extension#initialize}
      # @param ext_klass [Class] childe of
      #  {AssOle::AppExtension::Abstract::Extension}
      # @return [ext_klass] instance
      def exec(ext_klass, safe_mode)
        ext = ext_klass.new(self, safe_mode)
        ext.plug
        ext
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
    # @param klass (see Plug#exec)
    # @param safe_mode (see Plug#exec)
    # @return (see Plug#exec)
    def self.plug(info_base, ext_klass, safe_mode = true)
      Plug.new(info_base).exec(ext_klass, safe_mode)
    end
  end
end
