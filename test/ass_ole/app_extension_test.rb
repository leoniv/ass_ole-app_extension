require "test_helper"

module AssOle::AppExtensionTest
  describe ::AssOle::AppExtension::VERSION do
    it 'has a version_number' do
      refute_nil ::AssOle::AppExtension::VERSION
    end
  end

  describe AssOle::AppExtension do

    describe 'Smoky tests' do
      def ext_klass_8_3_10
        @ext_klass ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
          def platform_require
            Gem::Requirement.new('~> 8.3.10')
          end

          def path
            Env::EXT_8_3_10
          end

          def data
            newObject('BinaryData', real_win_path(path))
          end

          def name
            'TestExt8_3_10'
          end

          def app_requirements
            nil
          end
        end
      end

      def ext_klass_8_3_8
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
            'TestExt8_3_10'
          end

          def app_requirements
            nil
          end
        end
      end

      it '.plug' do
        begin
          extension = AssOle::AppExtension.plug(Env::IB, ext_klass_8_3_10, false)
          extension.exist?.must_equal true
          extension.plugged?.must_equal true
          extension.unplug!
          extension.exist?.must_equal false
          extension.plugged?.must_equal false
        ensure
          extension.unplug! if extension
        end
      end

      it '.all_extensions' do
        begin
          ext1 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_10, false).write!
          ext2 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_8, false).write!

          actual = AssOle::AppExtension.all_extensions(Env::IB)
          actual.size.must_equal 2

          actual.each do |spy|
            spy.must_be_instanse AssOle::AppExtension::Spy
            spy.exist?.must_equal true
            spy.name.must_match %r{TestExt8_3_(10|8)}i
            spy.plugged.must_equal true if spy.name =~ %r{TestExt8_3_10}i
            spy.plugged.must_equal false if spy.name =~ %r{TestExt8_3_8}i
          end
        ensure
          ext1.unplug! if ext1
          ext2.unplug! if ext2
        end
      end
    end

  end
end
