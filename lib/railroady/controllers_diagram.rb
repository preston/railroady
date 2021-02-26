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
    # options.exclude.map! {|e| "app/controllers/" + e}
    super options
    @graph.diagram_type = 'Controllers'
  end

  # Process controller files
  def generate
    $stderr.print "Generating controllers diagram\n" if @options.verbose
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
        $stderr.print "Warning: exception #{$ERROR_INFO} raised while trying to load controller class #{f}"
      end
    end
  end

  def get_files(prefix = '')
    files = !@options.specify.empty? ? Dir.glob(@options.specify) : Dir.glob(prefix << 'app/controllers/**/*_controller.rb')
    files += engine_files if @options.engine_controllers
    files -= Dir.glob(@options.exclude)
    files
  end

  def engine_files
    engines.collect { |engine| Dir.glob("#{engine.root}/app/controllers/**/*_controller.rb") }.flatten
  end

  def extract_class_name(filename)
    filename.match(%r{.*/controllers/(.*).rb$})[1].camelize
  end

  private

  # Load controller classes
  def load_classes
    disable_stdout
    # ApplicationController must be loaded first
    require APP_CONTROLLER
    get_files.each { |c| require "./#{c}" }
    enable_stdout
  rescue LoadError
    enable_stdout
    print_error 'controller classes'
    raise
  end

  # Proccess a controller class
  def process_class(current_class)
    $stderr.print "\tProcessing #{current_class}\n" if @options.verbose

    if @options.brief
      @graph.add_node ['controller-brief', current_class.name]
    elsif current_class.is_a? Class
      # Collect controller's methods
      node_attribs = { public: [],
                       protected: [],
                       private: [] }
      unless @options.hide_public
        current_class.public_instance_methods(false).sort.each do |m|
          node_attribs[:public] << m
        end
      end
      unless @options.hide_protected
        current_class.protected_instance_methods(false).sort.each do |m|
          node_attribs[:protected] << m
        end
      end
      unless @options.hide_private
        current_class.private_instance_methods(false).sort.each do |m|
          node_attribs[:private] << m
        end
      end
      @graph.add_node ['controller', current_class.name, node_attribs]
    elsif @options.modules && current_class.is_a?(Module)
      @graph.add_node ['module', current_class.name]
    end

    # Generate the inheritance edge (only for transitive subclasses of ApplicationControllers)
    if @options.inheritance && (transitive_subclasses_of(ApplicationController).include? current_class)
      @graph.add_edge ['is-a', current_class.superclass.name, current_class.name]
    end
  end

  def transitive_subclasses_of(klass)
    klass.subclasses | klass.subclasses.map { |subklass| transitive_subclasses_of(subklass) }.flatten
  end
end
