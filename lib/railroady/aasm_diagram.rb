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
    # options.exclude.map! {|e| e = "app/models/" + e}
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

  def get_files(prefix = '')
    files = !@options.specify.empty? ? Dir.glob(@options.specify) : Dir.glob(prefix + 'app/models/**/*.rb')
    files += Dir.glob('vendor/plugins/**/app/models/*.rb') if @options.plugins_models
    files -= Dir.glob(prefix + 'app/models/concerns/**/*.rb') unless @options.include_concerns
    files -= Dir.glob(@options.exclude)
    files
  end

  private

  # Load model classes
  def load_classes
    disable_stdout
    get_files.each { |m| require m }
    enable_stdout
  rescue LoadError
    enable_stdout
    print_error 'model classes'
    raise
  end  # load_classes

  # Process a model class
  def process_class(current_class)
    STDERR.print "\tProcessing #{current_class}\n" if @options.verbose

    # Only interested in aasm models.
    process_aasm_class(current_class)  if current_class.respond_to?(:aasm_states) || current_class.respond_to?(:aasm)
  end # process_class

  def process_aasm_class(current_class)
    node_attribs = []
    node_type = 'aasm'
    diagram_friendly_class_name = current_class.name.downcase.gsub(/[^a-z0-9\-_]+/i, '_')

    STDERR.print "\t\tprocessing as aasm\n" if @options.verbose
    current_class.aasm.states.each do |state|
      node_shape = (current_class.aasm.initial_state == state.name) ? ', peripheries = 2' : ''
      node_attribs << "#{diagram_friendly_class_name}_#{state.name} [label=#{state.name} #{node_shape}];"
    end
    @graph.add_node [node_type, current_class.name, node_attribs]

    current_class.aasm.events.each do |event|
      event.transitions.each do |transition|
        @graph.add_edge [
          'event',
          diagram_friendly_class_name + '_' + transition.from.to_s,
          diagram_friendly_class_name + '_' + transition.to.to_s,
          event.name.to_s
        ]
      end
    end
  end
end # class AasmDiagram
