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
      when /linux|cygwin/
        return "sed -r '#{regex}'"
      when /mac|darwin|bsd/
        return "sed -E '#{regex}'"
      else
        raise NotImplementedError
      end
    end

  end
end

namespace :diagram do

  @MODELS_ALL = RailRoady::RakeHelpers.full_path("models_complete.#{RailRoady::RakeHelpers.format}").freeze
  @MODELS_BRIEF = RailRoady::RakeHelpers.full_path("models_brief.#{RailRoady::RakeHelpers.format}").freeze
  @CONTROLLERS_ALL = RailRoady::RakeHelpers.full_path("controllers_complete.#{RailRoady::RakeHelpers.format}").freeze
  @CONTROLLERS_BRIEF = RailRoady::RakeHelpers.full_path("controllers_brief.#{RailRoady::RakeHelpers.format}").freeze
  @SED = RailRoady::RakeHelpers.sed

  namespace :models do

    desc 'Generates an class diagram for all models.'
    task :complete do
      f = @MODELS_ALL
      puts "Generating #{f}"
      sh "railroady -ilamM | #{@SED} | dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all models.'
    task :brief do
      f = @MODELS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilamM | #{@SED} | dot -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

  end

  namespace :controllers do

    desc 'Generates an class diagram for all controllers.'
    task :complete do
      f = @CONTROLLERS_ALL
      puts "Generating #{f}"
      sh "railroady -ilC | #{@SED} | neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all controllers.'
    task :brief do
      f = @CONTROLLERS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilC | #{@SED} | neato -T#{RailRoady::RakeHelpers.format} > #{f}"
    end

  end

  desc 'Generates all class diagrams.'
  task :all => ['diagram:models:complete', 'diagram:models:brief', 'diagram:controllers:complete', 'diagram:controllers:brief']

end
