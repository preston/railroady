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
  end
  

  # Print diagram
  def print
    if @options.output
      old_stdout = STDOUT.dup
      begin
        STDOUT.reopen(@options.output)
      rescue
        STDERR.print "Error: Cannot write diagram to #{@options.output}\n\n"
        exit 2
      end
    end
    
    if @options.xmi 
        STDERR.print "Generating XMI diagram\n" if @options.verbose
    	STDOUT.print @graph.to_xmi
    else
        STDERR.print "Generating DOT graph\n" if @options.verbose
        STDOUT.print @graph.to_dot 
    end

    if @options.output
      STDOUT.reopen(old_stdout)
    end
  end # print

  def process
    load_environment
  end

  private 
  
  # Load Rails application's environment
  def load_environment
    STDERR.print "Loading application environment\n" if @options.verbose
    begin
      disable_stdout
      l = File.join(Dir.pwd.to_s, @options.config_file)
      require l
      enable_stdout
    rescue LoadError
      enable_stdout
      print_error "application environment"
      raise
    end
    STDERR.print "Loading application classes as we go\n" if @options.verbose
  end

  # Prevents Rails application from writing to STDOUT
  def disable_stdout
    @old_stdout = STDOUT.dup
    #via  Tomas Matousek, http://www.ruby-forum.com/topic/205887
    STDOUT.reopen(::RUBY_PLATFORM =~ /djgpp|(cyg|ms|bcc)win|mingw/? "NUL" : "/dev/null")
  end

  # Restore STDOUT  
  def enable_stdout
    STDOUT.reopen(@old_stdout)
  end


  # Print error when loading Rails application
  def print_error(type)
    STDERR.print "Error loading #{type}.\n  (Are you running " +
                 "#{@options.app_name} on the aplication's root directory?)\n\n"
  end

  # Extract class name from filename
  def extract_class_name(filename)
    #filename.split('/')[2..-1].join('/').split('.').first.camelize
    # Fixed by patch from ticket #12742
    # File.basename(filename).chomp(".rb").camelize
    filename.split('/')[2..-1].collect { |i| i.camelize }.join('::').chomp(".rb")
  end

end # class AppDiagram
