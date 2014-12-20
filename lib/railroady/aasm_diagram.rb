# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

# AASM code provided by Ana Nelson (http://ananelson.com/)

require 'railroady/app_diagram'

# Diagram for Acts As State Machine
class AasmDiagram < AppDiagram

  def initialize(options = OptionsStruct.new)
    #options.exclude.map! {|e| e = "app/models/" + e}
    super options
    @graph.diagram_type = 'Models'
    # Processed habtm associations
    @habtm = []
  end

  # Process model files
  def generate
    STDERR.print "Generating AASM diagram\n" if @options.verbose
    get_files.each do |f|
      process_class extract_class_name(f).constantize
    end
  end

  def get_files(prefix ='')
    files = !@options.specify.empty? ? Dir.glob(@options.specify) : Dir.glob(prefix + "app/models/**/*.rb")
    files += Dir.glob("vendor/plugins/**/app/models/*.rb") if @options.plugins_models
    files -= Dir.glob(prefix + "app/models/concerns/**/*.rb") unless @options.include_concerns
    files -= Dir.glob(@options.exclude)
    files
  end

  private

  # Load model classes
  def load_classes
    begin
      disable_stdout
      get_files.each {|m| require m }
      enable_stdout
    rescue LoadError
      enable_stdout
      print_error "model classes"
      raise
    end
  end  # load_classes

  # Process a model class
  def process_class(current_class)

    STDERR.print "\tProcessing #{current_class}\n" if @options.verbose

    # Only interested in acts_as_state_machine models.
    process_acts_as_state_machine_class(current_class)  if current_class.respond_to?(:states)
    process_aasm_class(current_class)  if current_class.respond_to?(:aasm_states)
  end # process_class

  def process_acts_as_state_machine_class(current_class)
    dot_name = DiagramGraph.dotify(current_class.name.downcase)
    node_attribs = []
    node_type = 'aasm'
    
    STDERR.print "\t\tprocessing as acts_as_state_machine\n" if @options.verbose
    current_class.states.each do |state_name|
      state = current_class.read_inheritable_attribute(:states)[state_name]
      node_shape = (current_class.initial_state === state_name) ? ", peripheries = 2" : ""
      node_attribs << "#{dot_name}_#{state_name} [label=#{state_name} #{node_shape}];"
    end
    @graph.add_node [node_type, current_class.name, node_attribs]

    current_class.read_inheritable_attribute(:transition_table).each do |event_name, event|
      event.each do |transition|
        @graph.add_edge [
                         'event',
                         dot_name + "_" + transition.from.to_s,
                         dot_name + "_" + transition.to.to_s,
                         event_name.to_s
                        ]
      end
    end
  end

  def process_aasm_class(current_class)
    dot_name = DiagramGraph.dotify(current_class.name.downcase)
    node_attribs = []
    node_type = 'aasm'

    STDERR.print "\t\tprocessing as aasm\n" if @options.verbose
    current_class.aasm_states.each do |state|
      node_shape = (current_class.aasm_initial_state === state.name) ? ", peripheries = 2" : ""
      node_attribs << "#{dot_name}_#{state.name} [label=#{state.name} #{node_shape}];"
    end
    @graph.add_node [node_type, current_class.name, node_attribs]

    current_class.aasm_events.each do |event_name, event|
      event.all_transitions.each do |transition|
        @graph.add_edge [
                         'event',
                         dot_name + "_" + transition.from.to_s,
                         dot_name + "_" + transition.to.to_s,
                         event_name.to_s
                        ]
      end
    end
  end

end # class AasmDiagram
