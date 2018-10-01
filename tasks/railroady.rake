# This suite of tasks generate graphical diagrams via code analysis.
# A UNIX-like environment is required as well as:
#
# * The railroady gem. (http://github.com/preston/railroady)
# * The graphviz package which includes the `dot` and `neato` command-line utilities. MacPorts users can install in via `sudo port install graphviz`.
# * The `sed` command-line utility, which should already be available on all sane UNIX systems.
#
# Author: Preston Lee, http://railroady.prestonlee.com

# wrap helper methods so they don't conflict w/ methods on Object

require 'rbconfig'

module RailRoady
  class RakeHelpers
    def self.format
      @@DIAGRAM_FORMAT ||= 'svg'
    end

    # Returns an absolute path for the following file.
    def self.full_path(name = 'test.txt')
      f = File.join(Rails.root.to_s.gsub(' ', '\ '), 'doc', name)
      f.to_s
    end

    def self.sed
      regex = 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'
      case RbConfig::CONFIG['host_os']
      when /linux/
        return "sed -r '#{regex}'"
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        return "sed -r \"#{regex}\""
      when /mac|darwin|bsd/
        return "sed -E '#{regex}' | sed -E 's/D,.*//g'"     #filter debug info
      else
        fail NotImplementedError
      end
    end
  end
end

namespace :diagram do
  @MODELS_ALL         = RailRoady::RakeHelpers.full_path("models_complete.#{RailRoady::RakeHelpers.format}").freeze
  @MODELS_BRIEF       = RailRoady::RakeHelpers.full_path("models_brief.#{RailRoady::RakeHelpers.format}").freeze
  @CONTROLLERS_ALL    = RailRoady::RakeHelpers.full_path("controllers_complete.#{RailRoady::RakeHelpers.format}").freeze
  @CONTROLLERS_BRIEF  = RailRoady::RakeHelpers.full_path("controllers_brief.#{RailRoady::RakeHelpers.format}").freeze
  @SED                = RailRoady::RakeHelpers.sed

  namespace :setup do
    desc 'Perform any setup needed for the gem'
    task :create_new_doc_folder_if_needed do
      Dir.mkdir('doc') unless File.exist?('doc')
    end
  end

  namespace :models do
    desc 'Generates brief and complete class diagrams for all models.'
    task all: ['diagram:setup:create_new_doc_folder_if_needed', 'diagram:models:complete', 'diagram:models:brief']

    desc 'Generates a class diagram for all models.'
    task :complete do
      f = @MODELS_ALL
      puts "Generating #{f}"
      puts "railroady -lamM | #{@SED} > a.txt | tee a.txt| dot -T#{RailRoady::RakeHelpers.format} > #{f}"
      sh "railroady -lamM | #{@SED} > a.txt | tee a.txt | dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all models.'
    task :brief do
      f = @MODELS_BRIEF
      puts "Generating #{f}"
      sh "railroady -blamM | #{@SED} > a.txt | tee a.txt| dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates a class diagram for all models including those in engines'
    task :complete_with_engines do
      f = @MODELS_ALL
      puts "Generating #{f}"
      sh "railroady -ilamzM | #{@SED} > a.txt | tee a.txt| dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all models including those in engines'
    task :brief_with_engines do
      f = @MODELS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilamzM | #{@SED} > a.txt | tee a.txt| dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end
  end

  namespace :controllers do
    desc 'Generates brief and complete class diagrams for all controllers.'
    task all: ['diagram:setup:create_new_doc_folder_if_needed', 'diagram:controllers:complete', 'diagram:controllers:brief']

    desc 'Generates a class diagram for all controllers.'
    task :complete do
      f = @CONTROLLERS_ALL
      puts "Generating #{f}"
      sh "railroady -lC | #{@SED}  > a.txt | tee a.txt| neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all controllers.'
    task :brief do
      f = @CONTROLLERS_BRIEF
      puts "Generating #{f}"
      sh "railroady -blC | #{@SED} > a.txt | tee a.txt| neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates a class diagram for all controllers including those in engines'
    task :complete_with_engines do
      f = @CONTROLLERS_ALL
      puts "Generating #{f}"
      sh "railroady -ilC --engine-controllers > a.txt | tee a.txt| #{@SED} | neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all controllers including those in engines.'
    task :brief_with_engines do
      f = @CONTROLLERS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilC --engine-controllers > a.txt | tee a.txt| #{@SED} | neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end
  end

  desc 'Generates all class diagrams.'
  task all: [
    'diagram:setup:create_new_doc_folder_if_needed',
    'diagram:models:complete',
    'diagram:models:brief',
    'diagram:controllers:complete',
    'diagram:controllers:brief'
  ]

  desc 'Generates all class diagrams including those in engines'
  task all_with_engines: [
    'diagram:setup:create_new_doc_folder_if_needed',
    'diagram:models:complete_with_engines',
    'diagram:models:brief_with_engines',
    'diagram:controllers:complete_with_engines',
    'diagram:controllers:brief_with_engines'
  ]
end
