# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

require 'railroady/app_diagram'

# RailRoady controllers diagram
class ControllersDiagram < AppDiagram
 
  # as of Rails 2.3 the file is no longer application.rb but instead
  # application_controller.rb
  APP_CONTROLLER = File.exist?('app/controllers/application.rb') ? 'app/controllers/application.rb' : 'app/controllers/application_controller.rb'

  def initialize(options = OptionsStruct.new)
    #options.exclude.map! {|e| "app/controllers/" + e}
    super options
    @graph.diagram_type = 'Controllers'
  end

  # Process controller files
  def generate
    STDERR.print "Generating controllers diagram\n" if @options.verbose
    files = get_files
    # only add APP_CONTROLLER if it isn't already included from the glob above
    files << APP_CONTROLLER unless files.include? APP_CONTROLLER
    files.each do |f|
      class_name = extract_class_name(f)
      # ApplicationController's file is 'application.rb' in Rails < 2.3
      class_name += 'Controller' if class_name == 'Application'
      begin
        process_class class_name.constantize
      rescue Exception
        STDERR.print "Warning: exception #{$!} raised while trying to load controller class #{f}"
      end
    end 
  end # generate

  def get_files(prefix ='')
    files = !@options.specify.empty? ? Dir.glob(@options.specify) : Dir.glob(prefix << "app/controllers/**/*_controller.rb")
    files -= Dir.glob(@options.exclude)
    files
  end

  private
  # Load controller classes
  def load_classes
    begin
      disable_stdout
      # ApplicationController must be loaded first
      require APP_CONTROLLER
      get_files.each {|c| require "./#{c}" }
      enable_stdout
    rescue LoadError
      enable_stdout
      print_error "controller classes"
      raise
    end
  end # load_classes

  # Proccess a controller class
  def process_class(current_class)

    STDERR.print "\tProcessing #{current_class}\n" if @options.verbose

    if @options.brief
      @graph.add_node ['controller-brief', current_class.name]
    elsif current_class.is_a? Class 
      # Collect controller's methods
      node_attribs = {:public    => [], 
                      :protected => [], 
                      :private   => []}
      current_class.public_instance_methods(false).sort.each { |m|
        node_attribs[:public] << m
      } unless @options.hide_public
      current_class.protected_instance_methods(false).sort.each { |m|
        node_attribs[:protected] << m
      } unless @options.hide_protected
      current_class.private_instance_methods(false).sort.each { |m|
        node_attribs[:private] << m 
      } unless @options.hide_private
      @graph.add_node ['controller', current_class.name, node_attribs]
    elsif @options.modules && current_class.is_a?(Module)
      @graph.add_node ['module', current_class.name]
    end

    # Generate the inheritance edge (only for transitive subclasses of ApplicationControllers)
    if @options.inheritance && (transitive_subclasses_of(ApplicationController).include? current_class)
      @graph.add_edge ['is-a', current_class.superclass.name, current_class.name]
    end
  end # process_class

  def transitive_subclasses_of(klass)
    klass.subclasses | klass.subclasses.map {|subklass| transitive_subclasses_of(subklass)}.flatten
  end

end # class ControllersDiagram
