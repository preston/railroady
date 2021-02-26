# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

require 'railroady/diagram_graph'

# Root class for RailRoady diagrams
class AppDiagram
  def initialize(options = OptionsStruct.new)
    @options = options
    @graph = DiagramGraph.new
    @graph.show_label = @options.label
    @graph.alphabetize = @options.alphabetize
  end

  # Print diagram
  def print
    if @options.output
      old_stdout = $stdout.dup
      begin
        $stdout.reopen(@options.output)
      rescue
        $stderr.print "Error: Cannot write diagram to #{@options.output}\n\n"
        exit 2
      end
    end

    if @options.xmi
      $stderr.print "Generating XMI diagram\n" if @options.verbose
      $stdout.print @graph.to_xmi
    else
      $stderr.print "Generating DOT graph\n" if @options.verbose
      $stdout.print @graph.to_dot
    end

    $stdout.reopen(old_stdout) if @options.output
  end

  def process
    load_environment
  end

  # get all engines
  def engines
    engines = []

    if defined?(Rails)
      engines = if Rails::Application::Railties.respond_to?(:engines)
                  Rails::Application::Railties.engines
                else
                  # rails 4 way of getting engines
                  Rails::Engine.subclasses.map(&:instance)
                end
    end
    engines
  end

  private

  # Load Rails application's environment
  def load_environment
    $stderr.print "Loading application environment\n" if @options.verbose
    begin
      disable_stdout
      l = File.join(Dir.pwd.to_s, @options.config_file)
      require l
      enable_stdout
    rescue LoadError
      enable_stdout
      print_error 'application environment'
      raise
    end
    $stderr.print "Loading application classes as we go\n" if @options.verbose
  end

  # Prevents Rails application from writing to STDOUT
  def disable_stdout
    @old_stdout = $stdout.dup
    # via  Tomas Matousek, http://www.ruby-forum.com/topic/205887
    $stdout.reopen(::RUBY_PLATFORM =~ /djgpp|(cyg|ms|bcc)win|mingw/ ? 'NUL' : '/dev/null')
  end

  # Restore STDOUT
  def enable_stdout
    $stdout.reopen(@old_stdout)
  end

  # Print error when loading Rails application
  def print_error(type)
    $stderr.print "Error loading #{type}.\n  (Are you running " \
                 "#{@options.app_name} on the application's root directory?)\n\n"
  end

  # Extract class name from filename
  def extract_class_name(filename)
    # filename.split('/')[2..-1].join('/').split('.').first.camelize
    # Fixed by patch from ticket #12742
    # File.basename(filename).chomp(".rb").camelize
    filename.split('/')[2..-1].collect(&:camelize).join('::').chomp('.rb')
  end
end
