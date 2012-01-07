class MongoidDiagram < ModelsDiagram

  attr_accessor :magic_fields
  attr_reader :internal_fields

  def initialize(options = {})
    super options
    @magic_fields = [ "created_at", "updated_at" ]
    @internal_fields = ['_type', '_id']
  end

  # Process a model class
  def process_class(current_class)

    STDERR.print "\tProcessing #{current_class}\n" if @options.verbose

    generated = false

    if current_class.respond_to?'relations'

      node_attribs = []
      if @options.brief
        node_type = 'model-brief'
      else 
        node_type = 'model'

        # Collect model's content columns or all columns if all_columns flag is passed
        if @options.all_columns
          columns = current_class.fields
        else
          columns = current_class.fields.reject {|k,v| magic_fields.include?(k) }
        end
        #Reject '_type','_id'
        columns = current_class.fields.reject {|k,v| internal_fields.include?(k) }

        if @options.hide_magic 
          if current_class.respond_to?('_types')
            current_class._types.each do |type_field|
              magic_fields << type_field + "_count"
            end
          end
          columns = current_class.fields.reject {|k,v| magic_fields.include?(k) }
        end

        columns.each do |k,a|
          column = a.name
          column_type = if a.options[:identity]
                          'Id'
                        else
                          a.type.to_s.split('::').last.tap do |type|
                            type == 'Object' ? 'String' : type
                          end
                        end

          column += ' :' + column_type unless @options.hide_types
          node_attribs << column
        end
        
        node_attribs = node_attribs.sort

        ['created_at :Time', 'updated_at :Time'].each do |field|
          node_attribs.push(field) if node_attribs.delete(field)
        end
        
      end

      @graph.add_node [node_type, current_class.name, node_attribs]
      generated = true
      # Process class associations
      associations = current_class.relations
      if @options.inheritance && ! @options.transitive
        if current_class.superclass.respond_to?('relations')
          superclass_associations = current_class.superclass.relations
          associations = associations.select{|a| ! superclass_associations.include? a} 
        end
        # This doesn't works!
        # associations -= current_class.superclass.reflect_on_all_associations
      end
      associations.each do |name, a|
        process_association current_class.name, name, a
      end
    elsif @options.all && (current_class.is_a? Class)
      node_type = @options.brief ? 'class-brief' : 'class'
      @graph.add_node [node_type, current_class.name]
      generated = true
    elsif @options.modules && (current_class.is_a? Module)
      @graph.add_node ['module', current_class.name]
    end

    # Only consider meaningful inheritance relations for generated classes
    if @options.inheritance && generated && !current_class.superclass.respond_to?('relations')
      @graph.add_edge ['is-a', current_class.superclass.name, current_class.name]
    end      

  end # process_class

  # Process a model association
  def process_association(class_name, assoc_name, assoc)

    STDERR.print "\t\tProcessing model association #{assoc.name.to_s}\n" if @options.verbose

    # Skip "_in" associations
    return if ['referenced_in', 'embedded_in'].include?(assoc.macro.to_s) && !@options.show_belongs_to

    assoc_class_name = (assoc.class_name.respond_to? 'underscore') ? assoc.class_name.underscore.camelize : assoc.class_name
    #if assoc_class_name == assoc_name.to_s.singularize.camelize
    #  assoc_name = ''
    #end 

    if class_name.include?("::") && !assoc_class_name.include?("::")
      assoc_class_name = class_name.split("::")[0..-2].push(assoc_class_name).join("::")
    end
    assoc_class_name.gsub!(%r{^::}, '')

    if ['references_one', 'referenced_in', 'embeds_one','embedded_in'].include?(assoc.macro.to_s)
      assoc_type = 'one-one'
    elsif ['references_many', 'embeds_many'].include?(assoc.macro.to_s) 
      assoc_type = 'one-many'
    else # habtm or has_many, :through
      return if @habtm.include? [assoc.class_name, class_name, assoc_name]
      assoc_type = 'many-many'
      @habtm << [class_name, assoc.class_name, assoc_name]
    end  

    if ['embeds_one','embeds_many'].include?(assoc.macro.to_s)
      assoc_name += '(embedded)'
    end
    @graph.add_edge [assoc_type, class_name, assoc_class_name, assoc_name]    
  end # process_association

end
