require 'test_helper'

module AssOle::AppExtensionTest
  describe ::AssOle::AppExtension::Src::Xml do
    def inst(path, platform_require = Env::PLATFORM_REQUIRE)
      @inst ||= ::AssOle::AppExtension::Src::Xml.new(path, platform_require)
    end

    describe '#initialize' do
      it 'fail unless extension xml source' do
        e = proc {
          inst(File.expand_path('../',__FILE__))
        }.must_raise ArgumentError
        e.message.must_match %r{invalid extension xml source}i
      end

      describe 'attributes' do
        it '#path' do
          inst(Env::EXT_8_3_8_XML).path.must_equal Env::EXT_8_3_8_XML
        end

        it '#platform_require' do
          inst(Env::EXT_8_3_8_XML, :platform_require)
            .platform_require.must_equal :platform_require
        end
      end
    end

    describe '#to_binary' do
      def binary_path
        @binary_path ||= File.join(Dir.tmpdir, "app_ext_#{hash}.cfe")
      end

      before do
        FileUtils.rm_r binary_path if File.exist? binary_path
      end

      after do
        FileUtils.rm_r binary_path if File.exist? binary_path
      end

      it 'success' do
        File.exist?(binary_path).must_equal false
        inst(Env::EXT_8_3_8_XML).to_binary(binary_path).must_equal binary_path
        File.file?(binary_path).must_equal true
      end
    end
  end

  describe ::AssOle::AppExtension::Src::Cfe do
    def inst(path, platform_require = Env::PLATFORM_REQUIRE)
      @inst ||= ::AssOle::AppExtension::Src::Cfe.new(path, platform_require)
    end

    describe '#initialize' do
      it 'fail unless extension cfe file' do
        e = proc {
          inst(File.expand_path('../fake_file',__FILE__))
        }.must_raise ArgumentError
        e.message.must_match %r{extension must be a file}i
      end

      describe 'attributes' do
        it '#path' do
          inst(Env::EXT_8_3_8).path.must_equal Env::EXT_8_3_8
        end

        it '#platform_require' do
          inst(Env::EXT_8_3_8, :platform_require)
            .platform_require.must_equal :platform_require
        end
      end
    end

    describe '#to_xml' do
      def xml_path
        @xml_path ||= File.join(Dir.tmpdir, "app_ext_#{hash}.xml.src")
      end

      before do
        FileUtils.rm_r xml_path if File.exist? xml_path
      end

      after do
        FileUtils.rm_r xml_path if File.exist? xml_path
      end

      it 'success' do
        File.exist?(xml_path).must_equal false
        inst(Env::EXT_8_3_8).to_xml(xml_path).must_equal xml_path
        File.directory?(xml_path).must_equal true
      end
    end
  end
end
