require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe ModelsDiagram do
  describe 'file  processing' do
    it 'should select all the files under the models dir' do
      md = ModelsDiagram.new
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 3
    end

    it 'should include concerns if specified' do
      options = OptionsStruct.new(include_concerns: true)
      ad = ModelsDiagram.new(options)
      files = ad.get_files('test/file_fixture/')
      files.size.must_equal 5
    end

    it 'should exclude a specific file' do
      options = OptionsStruct.new(exclude: ['test/file_fixture/app/models/dummy1.rb'])
      md = ModelsDiagram.new(options)
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 2
    end

    it 'should exclude a glob pattern of files' do
      options = OptionsStruct.new(exclude: ['test/file_fixture/app/models/*/*.rb'])
      md = ModelsDiagram.new(options)
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 2
    end

    it 'should include only specific file' do
      options = OptionsStruct.new(specify: ['test/file_fixture/app/models/sub-dir/sub_dummy.rb'])
      md = ModelsDiagram.new(options)
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 1
    end

    it 'should include only specified files' do
      options = OptionsStruct.new(specify: ['test/file_fixture/app/models/{dummy1.rb,sub-dir/sub_dummy.rb}'])
      md = ModelsDiagram.new(options)
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 2
    end

    it 'should include only specified files and exclude specified files' do
      options = OptionsStruct.new(specify: ['test/file_fixture/app/models/{dummy1.rb,sub-dir/sub_dummy.rb}'],
                                  exclude: ['test/file_fixture/app/models/sub-dir/sub_dummy.rb'])
      md = ModelsDiagram.new(options)
      files = md.get_files('test/file_fixture/')
      files.size.must_equal 1
    end

    it 'should include engine files' do
      options = OptionsStruct.new(engine_models: true)
      md = ModelsDiagram.new(options)
      engines = [OpenStruct.new(root: 'test/file_fixture/lib')]
      md.stub(:engines, engines) do
        md.get_files.must_include('test/file_fixture/lib/app/models/dummy1.rb')
      end
    end
  end

  describe '#extract_class_name' do
    describe 'class can be found' do
      describe 'module without namespace' do
        module AuthorSettings
        end

        it 'does not take every models subdirectory as a namespace' do
          md = ModelsDiagram.new(OptionsStruct.new)

          md.extract_class_name('test/file_fixture/app/models/concerns/author_settings.rb').must_equal 'AuthorSettings'
        end
      end

      describe 'module with parent namespace / class' do
        class User
          module Authentication
          end
        end

        it 'does not take every models subdirectory as a namespace' do
          md = ModelsDiagram.new(OptionsStruct.new)

          md.extract_class_name('test/file_fixture/app/models/concerns/user/authentication.rb').must_equal 'User::Authentication'
        end
      end
    end

    describe 'class cannot be found' do
      it 'returns the full class name' do
        md = ModelsDiagram.new(OptionsStruct.new)

        md.extract_class_name('test/file_fixture/app/models/concerns/dummy.rb').must_equal 'Concerns::Dummy'
      end
    end
  end

describe '#process_association' do
  after do
    Object.send(:remove_const, :Child)
  end
  before do
    module ActiveRecord
      class Base; end;
    end
    class Child < ActiveRecord::Base;
      def self.macro
        ''
      end
      def self.options
        []
      end
    end;
  end
  it 'should exclude a specific class' do
    options = OptionsStruct.new(excluded_classes: ['Child'])
    md = ModelsDiagram.new(options)
    md.process_association('fake', Child).must_equal nil
  end
end

  describe '#include_inheritance?' do
    after do
      Object.send(:remove_const, :Child)
    end
    describe 'when class inherits from another app class' do
      before do
        class Parent; end;
        class Child < Parent; end;
      end
      it 'returns true' do
        md = ModelsDiagram.new(OptionsStruct.new)
        md.include_inheritance?(Child).must_equal true
      end
      after do
        Object.send(:remove_const, :Parent)
      end
    end

    describe 'when class inherits from Object' do
      before do
        class Child < Object; end;
      end
      it 'returns false' do
        md = ModelsDiagram.new(OptionsStruct.new)
        md.include_inheritance?(Child).must_equal false
      end
    end

    describe 'when class inherits from ActiveRecord::Base' do
      before do
        module ActiveRecord
          class Base; end;
        end
        class Child < ActiveRecord::Base; end;
      end
      it 'returns false' do
        md = ModelsDiagram.new(OptionsStruct.new)
        md.include_inheritance?(Child).must_equal false
      end
      after do
        Object.send(:remove_const, :ActiveRecord)
      end
    end

    describe 'when class inherits from CouchRest::Model::Base' do
      before do
        module CouchRest
          module Model
            class Base; end;
          end
        end
        class Child < CouchRest::Model::Base; end;
      end
      it 'returns false' do
        md = ModelsDiagram.new(OptionsStruct.new)
        md.include_inheritance?(Child).must_equal false
      end
      after do
        Object.send(:remove_const, :CouchRest)
      end
    end
  end
end
