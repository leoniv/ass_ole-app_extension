require "test_helper"

module AssOle::AppExtensionTest
  describe ::AssOle::AppExtension::VERSION do
    it 'has a version_number' do
      refute_nil ::AssOle::AppExtension::VERSION
    end
  end

  describe AssOle::AppExtension do

    describe 'Smoky test' do
      def ext_klass
        @ext_klass ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
          def platform_require
            Gem::Requirement.new('~> 8.3.10.0')
          end

          def path
            Env::EXT_8_3_10
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
        extension.plugged?.must_equal true
      end
    end

  end
end
