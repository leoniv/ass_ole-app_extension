$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'simplecov'
require "ass_ole/app_extension"
require 'ass_maintainer/info_base'

module AssOle::AppExtensionTest
    module Env
      extend AssLauncher::Api
      PLATFORM_REQUIRE = '~> 8.3.10.0'
      FIXT_DIR = File.expand_path("../fixtures", __FILE__)
      EXT_8_3_8 = File.join(FIXT_DIR, '8_3_8.cfe')
      EXT_8_3_10 = File.join(FIXT_DIR, '8_3_10.cfe')
      EXT_8_3_10_PREFIX_CONFLICT = File.join(FIXT_DIR, '8_3_10_prefix_conflict.cfe')
      TMP_DIR = Dir.tmpdir

      def self.make_ib(name, platform_require)
        AssMaintainer::InfoBase
          .new(name, cs_file(file: File.join(TMP_DIR, name)), false,
               platform_require: platform_require)
      end

      IB = make_ib('ass_ole-app_extension_test.ib', PLATFORM_REQUIRE).rebuild! :yes
    end

    module Runtimes
      module Ext
        is_ole_runtime :external
        run Env::IB
      end

      module Thin
        is_ole_runtime :thin
        run Env::IB
        ole_connector.Visible = false
      end
    end
end

require "minitest/autorun"
