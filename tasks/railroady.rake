# This suite of tasks generate graphical diagrams via code analysis.
# A UNIX-like environment is required as well as:
# 
# * The railroady gem. (http://github.com/preston/railroady)
# * The graphviz package which includes the `dot` and `neato` command-line utilities. MacPorts users can install in via `sudo port install graphviz`.
# * The `sed` command-line utility, which should already be available on all sane UNIX systems.
#
# Author: Preston Lee, http://railroady.prestonlee.com 

# Returns an absolute path for the following file.
def format
  @@DIAGRAM_FORMAT ||= 'SVG'
end

def full_path(name = 'test.txt')
  f = File.join(Rails.root.to_s.gsub(' ', '\ '), 'doc', name)
  f.to_s
end

namespace :diagram do

  @MODELS_ALL = full_path("models_complete.#{format}").freeze
  @MODELS_BRIEF = full_path("models_brief.#{format}").freeze
  @CONTROLLERS_ALL = full_path("controllers_complete.#{format}").freeze
  @CONTROLLERS_BRIEF = full_path("controllers_brief.#{format}").freeze

  namespace :models do

    desc 'Generates an class diagram for all models.'
    task :complete do
      f = @MODELS_ALL
      puts "Generating #{f}"
      sh "railroady -ilamM | dot -T#{format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all models.'
    task :brief do
      f = @MODELS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilamM | dot -T#{format} > #{f}"
    end

  end

  namespace :controllers do

    desc 'Generates an class diagram for all controllers.'
    task :complete do
      f = @CONTROLLERS_ALL
      puts "Generating #{f}"
      sh "railroady -ilC | neato -T#{format} > #{f}"
    end

    desc 'Generates an abbreviated class diagram for all controllers.'
    task :brief do
      f = @CONTROLLERS_BRIEF
      puts "Generating #{f}"
      sh "railroady -bilC | neato -T#{format} > #{f}"
    end

  end

  desc 'Generates all class diagrams.'
  task :all => ['diagram:models:complete', 'diagram:models:brief', 'diagram:controllers:complete', 'diagram:controllers:brief']

end
