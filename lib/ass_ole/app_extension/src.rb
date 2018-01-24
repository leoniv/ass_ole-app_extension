module AssOle
  module AppExtension
    # Provides classes for working with application extension sources like a
    # +.cfe+ file or +xml+ files
    module Src
      require 'ass_maintainer/info_bases/tmp_info_base'
      # @abstract
      class Abstract
        include AssMaintainer::InfoBases::TmpInfoBase::Api

        attr_reader :path, :platform_require

        # @param path [String] path to extension source
        # @param platform_require [String] requirement for 1C:Enterprise
        #  platform version
        def initialize(path, platform_require = '~> 8.3.8')
          path_set(path)
          @platform_require = platform_require
        end

        def path_set(path)
          @path = path
          fail ArgumentError, "Path not exist: #{path}" unless File.exist? path
        end
        private :path_set
      end

      # Class for extension +xml+ files source
      # @example Convert xml extension source to +.cfe+ binary file
      #  src = AssOle::AppExtension::Src::Xml.new('foo_ext/xml.src', '~> 8.3.9')
      #  src.to_binary('foo_ext.cfe') #=> 'foo_ext.cfe'
      class Xml < Abstract
        def path_set(path)
          super
          fail ArgumentError, "Invalid extension xml source: `#{path}'" unless\
            File.file? root_file
        end
        private :path_set

        # Build binary +.cfe+ file from +xml+ source
        # @param dest_path [String] +.cfe+ file path
        def to_binary(dest_path)
          src_path = path
          with_tmp_ib platform_require: platform_require do |ib|
            ib.designer do
              _loadConfigFromFiles src_path do
                _Extension 'WTF1C'
              end
            end.run.wait.result.verify!

            ib.designer do
              _DumpCfg dest_path do
                _Extension 'WTF1C'
              end
            end.run.wait.result.verify!
          end
          dest_path
        end

        # @return [String] path to +Configuration.xml+ root file
        def root_file
          File.join(path, 'Configuration.xml')
        end
      end

      # Class for extension +.cfe+ binary file
      # @example Convert +.cfe+ extension binary file to xml files
      #  src = AssOle::AppExtension::Src::Cfe.new('foo_ext.cfe', '~> 8.3.9')
      #  src.to_xml('foo_ext/xml.src') #=> 'foo_ext/xml.src'
      class Cfe < Abstract
        # Disassemble binary +.cfe+ to +xml+ source
        # @param dest_path [String] +xml+ sorce dir
        def to_xml(dest_path)
          src_path = path
          with_tmp_ib platform_require: platform_require do |ib|
            ib.designer do
              _loadCfg src_path do
                _Extension 'WTF1C'
              end
            end.run.wait.result.verify!

            ib.designer do
              _DumpConfigToFiles dest_path do
                _Extension 'WTF1C'
              end
            end.run.wait.result.verify!
          end
          dest_path
        end
      end
    end
  end
end
