require "test_helper"

module AssOle::AppExtensionTest
  describe ::AssOle::AppExtension::VERSION do
    it 'has a version_number' do
      refute_nil ::AssOle::AppExtension::VERSION
    end
  end

  describe AssOle::AppExtension do
    like_ole_runtime Runtimes::Thin

    def ext_klass
      @ext_klass ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
        def platform_require
          Gem::Requirement.new('~> 8.3.8')
        end

        def path
          Env::EXT_8_3_8
        end

        def data
          newObject('BinaryData', real_win_path(path))
        end

        def name
          'TestExt'
        end

        def app_requirements
          nil
        end
      end
    end

    it '.plug' do
      extension = AssOle::AppExtension.plug(Env::IB, ext_klass, false)

      require 'pry'
      binding.pry
    end
  end
end
