# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

require 'railroady/app_diagram'

# RailRoady models diagram
class ModelsDiagram < AppDiagram
  def initialize(options = OptionsStruct.new)
    super options
    @graph.diagram_type = 'Models'
    # Processed habtm associations
    @habtm = []
  end

  # Process model files
  def generate
    STDERR.puts "Generating models diagram" if @options.verbose
    get_files.each do |f|
      begin
        process_class extract_class_name(f).constantize
      rescue Exception
        STDERR.puts "Warning: exception #{$!} raised while trying to load model class #{f}"
      end

    end
  end

  def get_files(prefix ='')
    files = !@options.specify.empty? ? Dir.glob(@options.specify) : Dir.glob(prefix << "app/models/**/*.rb")
    files += Dir.glob("vendor/plugins/**/app/models/*.rb") if @options.plugins_models
    files -= Dir.glob(@options.exclude)
    files
  end

  # Process a model class
  def process_class(current_class)
    STDERR.puts "Processing #{current_class}" if @options.verbose

    generated =
      if defined?(CouchRest::Model::Base) && current_class.new.is_a?(CouchRest::Model::Base)
        process_couchrest_model(current_class)
      elsif defined?(Mongoid::Document) && current_class.new.is_a?(Mongoid::Document)
        process_mongoid_model(current_class)
      elsif defined?(DataMapper::Resource) && current_class.new.is_a?(DataMapper::Resource)
        process_datamapper_model(current_class)
      elsif current_class.respond_to?'reflect_on_all_associations'
        process_active_record_model(current_class)
      elsif @options.all && (current_class.is_a? Class)
        process_basic_class(current_class)
      elsif @options.modules && (current_class.is_a? Module)
        process_basic_module(current_class)
      end

    if @options.inheritance && generated && include_inheritance?(current_class)
      @graph.add_edge ['is-a', current_class.superclass.name, current_class.name]
    end

  end # process_class

  def include_inheritance?(current_class)
    STDERR.puts current_class.superclass if @options.verbose
    (defined?(ActiveRecord::Base) && current_class.superclass != ActiveRecord::Base) ||
    (defined?(CouchRest::Model::Base) && current_class.superclass != CouchRest::Model::Base) ||
    (current_class.superclass != Object)
  end

  def process_basic_class(current_class)
    node_type = @options.brief ? 'class-brief' : 'class'
    @graph.add_node [node_type, current_class.name]
    true
  end

  def process_basic_module(current_class)
    @graph.add_node ['module', current_class.name]
    false
  end

  def process_active_record_model(current_class)
    node_attribs = []
    if @options.brief || current_class.abstract_class?
      node_type = 'model-brief'
    else
      node_type = 'model'

      # Collect model's content columns
      #content_columns = current_class.content_columns

      if @options.hide_magic
        # From patch #13351
        # http://wiki.rubyonrails.org/rails/pages/MagicFieldNames
        magic_fields = [
          "created_at", "created_on", "updated_at", "updated_on",
          "lock_version", "type", "id", "position", "parent_id", "lft",
          "rgt", "quote", "template"
        ]
        magic_fields << current_class.table_name + "_count" if current_class.respond_to? 'table_name'
        content_columns = current_class.content_columns.select {|c| ! magic_fields.include? c.name}
      else
        content_columns = current_class.columns
      end

      content_columns.each do |a|
        content_column = a.name
        content_column += ' :' + a.type.to_s unless @options.hide_types
        node_attribs << content_column
      end
    end
    @graph.add_node [node_type, current_class.name, node_attribs]

    # Process class associations
    associations = current_class.reflect_on_all_associations
    if @options.inheritance && ! @options.transitive
      superclass_associations = current_class.superclass.reflect_on_all_associations

      associations = associations.select{|a| ! superclass_associations.include? a}
      # This doesn't works!
      # associations -= current_class.superclass.reflect_on_all_associations
    end

    associations.each do |a|
      process_association current_class.name, a
    end

    true
  end

  def process_datamapper_model(current_class)
    node_attribs = []
    if @options.brief #|| current_class.abstract_class?
      node_type = 'model-brief'
    else
      node_type = 'model'

      # Collect model's properties
      props = current_class.properties.sort_by(&:name)

      if @options.hide_magic
        # From patch #13351
        # http://wiki.rubyonrails.org/rails/pages/MagicFieldNames
        magic_fields =
          ["created_at", "created_on", "updated_at", "updated_on", "lock_version", "_type", "_id",
           "position", "parent_id", "lft", "rgt", "quote", "template"]
        props = props.select {|c| !magic_fields.include?(c.name.to_s) }
      end

      props.each do |a|
        prop = a.name.to_s
        prop += ' :' + a.class.name.split('::').last unless @options.hide_types
        node_attribs << prop
      end
    end
    @graph.add_node [node_type, current_class.name, node_attribs]

    # Process relationships
    relationships = current_class.relationships

    # TODO: Manage inheritance

    relationships.each do |a|
      process_datamapper_relationship current_class.name, a
    end

    true
  end

  def process_mongoid_model(current_class)
    node_attribs = []

    if @options.brief
      node_type = 'model-brief'
    else
      node_type = 'model'

      # Collect model's content columns
      content_columns = current_class.fields.values.sort_by(&:name)

      if @options.hide_magic
        # From patch #13351
        # http://wiki.rubyonrails.org/rails/pages/MagicFieldNames
        magic_fields = [
          "created_at", "created_on", "updated_at", "updated_on",
          "lock_version", "_type", "_id", "position", "parent_id", "lft",
          "rgt", "quote", "template"
        ]
        content_columns = content_columns.select {|c| !magic_fields.include?(c.name) }
      end

      content_columns.each do |a|
        content_column = a.name
        content_column += " :#{a.type}" unless @options.hide_types
        node_attribs << content_column
      end
    end

    @graph.add_node [node_type, current_class.name, node_attribs]

    # Process class associations
    associations = current_class.relations.values

    if @options.inheritance && !@options.transitive &&
      current_class.superclass.respond_to?(:relations)
      associations -= current_class.superclass.relations.values
    end

    associations.each do |a|
      process_association current_class.name, a
    end

    true
  end

  ##
  # Some very basic CouchRest::Model support
  #
  # Field types note: the field's type is rendered only if it's explicitly
  # specified in a model.
  #
  def process_couchrest_model(current_class)
    node_attribs = []

    if @options.brief
      node_type = 'model-brief'
    else
      node_type = 'model'

      # Collect model's content columns
      content_columns = current_class.properties

      if @options.hide_magic
        magic_fields = [
          "created_at", "updated_at",
          "type", "_id", "_rev"
        ]
        content_columns = content_columns.select {|c| !magic_fields.include?(c.name) }
      end

      content_columns.each do |a|
        content_column = a.name
        content_column += " :#{a.type}" unless @options.hide_types || a.type.nil?
        node_attribs << content_column
      end
    end

    @graph.add_node [node_type, current_class.name, node_attribs]

    true
  end

  # Process a model association
  def process_association(class_name, assoc)
    STDERR.puts "- Processing model association #{assoc.name.to_s}" if @options.verbose

    # Skip "belongs_to" associations
    macro = assoc.macro.to_s
    return if %w[belongs_to referenced_in].include?(macro) && !@options.show_belongs_to

    # Skip "through" associations
    through = assoc.options.include?(:through)
    return if through && @options.hide_through

    #TODO:
    # FAIL: assoc.methods.include?(:class_name)
    # FAIL: assoc.responds_to?(:class_name)
    assoc_class_name = assoc.class_name rescue nil
    assoc_class_name ||= assoc.name.to_s.underscore.singularize.camelize

    # Only non standard association names needs a label

    # from patch #12384
    # if assoc.class_name == assoc.name.to_s.singularize.camelize
    if assoc_class_name == assoc.name.to_s.singularize.camelize
      assoc_name = ''
    else
      assoc_name = assoc.name.to_s
    end

    # Patch from "alpack" to support classes in a non-root module namespace. See: http://disq.us/yxl1v
    if class_name.include?("::") && !assoc_class_name.include?("::")
      assoc_class_name = class_name.split("::")[0..-2].push(assoc_class_name).join("::")
    end
    assoc_class_name.gsub!(%r{^::}, '')

    if %w[has_one references_one embeds_one].include?(macro)
      assoc_type = 'one-one'
    elsif macro == 'has_many' && (!assoc.options[:through]) ||
          %w[references_many embeds_many].include?(macro)
      assoc_type = 'one-many'
    else # habtm or has_many, :through
      # Add FAKE associations too in order to understand mistakes
      return if @habtm.include? [assoc_class_name, class_name, assoc_name]
      assoc_type = 'many-many'
      @habtm << [class_name, assoc_class_name, assoc_name]
    end
    # from patch #12384
    # @graph.add_edge [assoc_type, class_name, assoc.class_name, assoc_name]
    @graph.add_edge [assoc_type, class_name, assoc_class_name, assoc_name]
  end # process_association

  # Process a DataMapper relationship
  def process_datamapper_relationship(class_name, relation)
    STDERR.puts "- Processing DataMapper model relationship #{relation.name.to_s}" if @options.verbose

    # Skip "belongs_to" relationships
    dm_type = relation.class.to_s.split('::')[-2]
    return if dm_type == 'ManyToOne' && !@options.show_belongs_to

    dm_parent_model = relation.parent_model.to_s
    dm_child_model = relation.child_model.to_s

    assoc_class_name = ''
    # Get the assoc_class_name
    if dm_parent_model.eql?(class_name)
      assoc_class_name = dm_child_model
    else
      assoc_class_name = dm_parent_model
    end

    # Only non standard association names needs a label
    assoc_name = ''
    if !(relation.name.to_s.singularize.camelize.eql?(assoc_class_name.split('::').last))
      assoc_name = relation.name.to_s
    end

    # TO BE IMPROVED
    rel_type = 'many-many' # default value for ManyToOne and ManyToMany
    if dm_type == 'OneToOne'
      rel_type = 'one-one'
    elsif dm_type == 'OneToMany'
      rel_type = 'one-many'
    end

    @graph.add_edge [rel_type, class_name, assoc_class_name, assoc_name ]
  end

end # class ModelsDiagram


