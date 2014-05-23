require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe ControllersDiagram do
  describe 'file processing' do

    it 'should select all the files under the controllers dir' do
      cd = ControllersDiagram.new
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 4
    end

    it 'should exclude a specific file' do
      options = OptionsStruct.new(:exclude => ['test/file_fixture/app/controllers/dummy1_controller.rb'])
      cd = ControllersDiagram.new(options)
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 3
    end

    it 'should exclude a glob pattern of files' do
      options = OptionsStruct.new(:exclude => ['test/file_fixture/app/controllers/sub-dir/*.rb'])
      cd = ControllersDiagram.new(options)
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 3
    end

    it 'should include only specific file' do
      options = OptionsStruct.new(:specify => ['test/file_fixture/app/controllers/sub-dir/sub_dummy_controller.rb'])
      cd = ControllersDiagram.new(options)
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 1
    end

    it 'should include only specified files' do
      options = OptionsStruct.new(:specify => ['test/file_fixture/app/controllers/{dummy1_*.rb,sub-dir/sub_dummy_controller.rb}'])
      cd = ControllersDiagram.new(options)
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 2
    end

    it 'should include only specified files and exclude specified files' do
      options = OptionsStruct.new(:specify => ['test/file_fixture/app/controllers/{dummy1_*.rb,sub-dir/sub_dummy_controller.rb}'],
                                  :exclude => ['test/file_fixture/app/controllers/sub-dir/sub_dummy_controller.rb'])
      cd = ControllersDiagram.new(options)
      files = cd.get_files("test/file_fixture/")
      files.size.must_equal 1
    end

    it "should include engine files" do
      options = OptionsStruct.new(:engine_controllers => true)
      md = ControllersDiagram.new(options)
      engines = [OpenStruct.new(:root => "test/file_fixture/lib")]
      md.stub(:engines, engines) do
        md.get_files.must_include("test/file_fixture/lib/app/controllers/dummy/dummy_controller.rb")
      end
    end
    

  end
end
