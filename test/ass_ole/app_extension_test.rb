require "test_helper"

module AssOle::AppExtensionTest
  describe ::AssOle::AppExtension::VERSION do
    it 'has a version_number' do
      refute_nil ::AssOle::AppExtension::VERSION
    end
  end

  describe ::AssOle::AppExtension::Abstract::Extension do
    def klass
      ::AssOle::AppExtension::Abstract::Extension
    end

    it 'Extension include AbstractMethods' do
      klass.include?(::AssOle::AppExtension::Abstract::Extension::AbstractMethods).must_equal true
    end

    it 'Extension include AssOle::Snippets::Shared::AppCompatibility' do
      klass.include?(AssOle::Snippets::Shared::AppCompatibility).must_equal true
    end

    describe 'Abstract interface' do
      def inst
        @inst ||= klass.new(nil, nil)
      end

      def method_must_be_abstract(obj, method, *args)
        e = proc {
          obj.send(method, *args)
        }.must_raise NotImplementedError
        e.message.must_match %r{Abstract}i
      end

      it '#data must be Abstract' do
        method_must_be_abstract(inst, :data)
      end

      it '#platform_require must be Abstract' do
        method_must_be_abstract(inst, :platform_require)
      end

      it '#app_requirements must be Abstract' do
        method_must_be_abstract(inst, :app_requirements)
      end

      it '#name must be Abstract' do
        method_must_be_abstract(inst, :name)
      end

      it '#version must be Abstract' do
        method_must_be_abstract(inst, :version)
      end
    end

    def ext_stub
      @ext_stub ||= Class.new(klass) do
        def metaData
          self
        end

        def Name
          'fake_app_name'
        end

        def Version
          '666'
        end
      end.new(nil, nil)
    end

    it '#app_name' do
      ext_stub.app_name.must_equal 'fake_app_name'
    end

    it '#app_version' do
      ext_stub.app_version.must_equal Gem::Version.new('666')
    end

    describe '#verify_version_compatibility!' do
      def incomp_ext
        @incomp_ext ||= Class.new(klass) do
          def platform_require
            Gem::Requirement.new '> 666'
          end

          def app_compatibility_version
            Gem::Version.new '555'
          end

          def verify_application!
            nil
          end
        end.new(nil, nil)
      end

      def comp_ext
        @incomp_ext ||= Class.new(klass) do
          def platform_require
            Gem::Requirement.new '> 555'
          end

          def app_compatibility_version
            Gem::Version.new '666'
          end

          def verify_application!
            nil
          end
        end.new(nil, nil)
      end

      it 'fail IncompatibleError' do
        e = proc {
          incomp_ext.verify_version_compatibility!
        }.must_raise AssOle::AppExtension::IncompatibleError
      end

      it 'return nil' do
        comp_ext.verify_version_compatibility!.must_be_nil
      end

      it '#verify! fail' do
        e = proc {
          incomp_ext.verify_version_compatibility!
        }.must_raise AssOle::AppExtension::IncompatibleError
      end

      it '#verify! nil' do
        comp_ext.verify!.must_be_nil
      end
    end

    describe '#verify_application!' do
      def ext_stub(app_name, app_version, app_requirements)
        @ext_stub ||= Class.new(klass) do
          attr_reader :app_name, :app_version, :app_requirements
          def initialize(app_name, app_version, app_requirements)
            @app_name = app_name
            @app_version = app_version
            @app_requirements = app_requirements
          end

          def verify_version_compatibility!
            nil
          end
        end.new app_name, app_version, app_requirements
      end

      it 'do nothing uless app_requirements' do
        ext_stub(nil, nil, nil).verify_application!.must_be_nil
      end

      it 'not fail' do
        ext_stub('fake_app', Gem::Version.new('0'), {fake_app: '>= 0'}).verify_application!
      end

      it 'fail if invalid app_name' do
        e = proc {
          ext_stub('invalid_app', nil, {fake_app: '>= 0'} ).verify!
        }.must_raise AssOle::AppExtension::IncompatibleError
        e.message.must_match %r{Unsupported application `invalid_app`}i
      end

      it 'fail if invalid app_version' do
        e = proc {
          ext_stub('fake_app', Gem::Version.new('0'), {fake_app: '> 0'} ).verify!
        }.must_raise AssOle::AppExtension::IncompatibleError
        e.message.must_match %r{Unsupported application version}i
      end
    end
  end

  describe 'Smoky tests' do
    def ext_klass_8_3_10
      @ext_klass_8_3_10 ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
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

    def ext_klass_8_3_10_prefix_conflict
      @ext_klass_8_3_10_prefix_conflict ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
        def platform_require
          Gem::Requirement.new('~> 8.3.10')
        end

        def path
          Env::EXT_8_3_10_PREFIX_CONFLICT
        end

        def data
          newObject('BinaryData', real_win_path(path))
        end

        def name
          'TestExt8_3_10_prefix_conflict'
        end

        def app_requirements
          nil
        end
      end
    end

    def ext_klass_8_3_8
      @ext_klass_8_3_8 ||= Class.new(AssOle::AppExtension::Abstract::Extension) do
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
          'TestExt8_3_8'
        end

        def app_requirements
          nil
        end
      end
    end

    describe AssOle::AppExtension do
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
    end

    describe AssOle::AppExtension::Abstract::Extension do
      like_ole_runtime Runtimes::Ext

      def extension
        @extension ||= ext_klass_8_3_8.new(ole_runtime_get)
      end

      after do
        @extension.delete! if @extension
        FileUtils.rm_r @ext_dir if @ext_dir && File.exist?(@ext_dir)
      end

      def ext_dir
        @ext_dir ||= FileUtils.mkdir_p(File.join(Dir.tmpdir, "#{hash}"))[0]
      end

      describe '#save_stored_data' do
        it 'return nil if not exist' do
          extension.exist?.must_equal false
          extension.save_stored_data(nil).must_be_nil
        end

        it 'return path if exist' do
          extension.write!.exist?.must_equal true
          file_path = extension.save_stored_data(ext_dir)
          File.file?(file_path).must_equal true
        end
      end

      it '#apply_warnings' do
        extension.apply_warnings.must_equal []
      end

      it '#apply_errors' do
        extension.apply_errors.size.must_be :>, 0
        extension.apply_errors[0].must_be_instance_of WIN32OLE
        extension.apply_errors[0].must_be :ole_respond_to?, :Description
      end
    end

    describe AssOle::AppExtension::Spy do
      def ole_runtime_get
        Runtimes::Ext
      end

      def ole_stub
        @ole_stub ||= (mock = mock()
                       mock.stubs(Name: 'fake_ole', GetData: 'fake_data')
                       mock)
      end

      def spy
        @spy ||= AssOle::AppExtension::Spy.new(ole_runtime_get, ole_stub)
      end

      it '#ole_get' do
        spy.send(:ole_get).must_equal ole_stub
      end

      it '#ole' do
        spy.ole.must_equal ole_stub
      end

      it '#plug!' do
        spy.plug!.must_equal spy
      end

      it '#unplug!' do
        spy.unplug!.must_equal spy
      end

      it '#verify!' do
        spy.verify!.must_equal spy
      end

      it '#name' do
        spy.name.must_match 'fake_ole'
      end

      it '#data' do
        spy.data.must_equal 'fake_data'
      end

      it '#platform_require' do
        spy.platform_require.must_equal Gem::Requirement.new('~> 0')
      end

      it '#unsafe_mode_set' do
        spy.send(:unsafe_mode_set).must_equal ole_stub
      end

      it '.explore' do
        begin
          ext1 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_10, false).write!
          ext2 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_8, false).write!

          actual = AssOle::AppExtension::Spy.explore(Env::IB)
          actual.size.must_equal 2

          actual.each do |spy|
            spy.must_be_instance_of AssOle::AppExtension::Spy
            spy.exist?.must_equal true
            spy.name.must_match %r{TestExt8_3_(10|8)}i
            spy.plugged?.must_equal true if spy.name =~ %r{TestExt8_3_10}i
            spy.plugged?.must_equal false if spy.name =~ %r{TestExt8_3_8}i
          end
        ensure
          ext1.unplug! if ext1
          ext2.unplug! if ext2
        end
      end
    end

    it 'Prefix conflict' do
      begin
        ext2 = nil
        ext1 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_10, false).write!
        e = proc {
          ext2 = AssOle::AppExtension::Plug.new(Env::IB).new_ext(ext_klass_8_3_10_prefix_conflict, false).plug
        }.must_raise AssOle::AppExtension::ApplyError

        e.message.must_match %r{(Конфликт|Conflict)}i
      ensure
        ext1.unplug! if ext1
        ext2.unplug! if ext2
      end
    end
  end
end
