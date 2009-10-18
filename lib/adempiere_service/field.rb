module AdempiereService
  class Field
    class_inheritable_accessor :attributes
    self.attributes = [:adempiere_name, :name, :read_only]
    attr_accessor *attributes
  
    def initialize name, field_name_or_options
      options = if field_name_or_options.is_a? Array
        raise ArgumentError, "Too many options" unless field_name_or_options.size == 2
        field_name_or_options.extract_options!.
                              symbolize_keys!.
                              merge({:adempiere_name => field_name_or_options.first})
      elsif field_name_or_options.is_a? Hash
        field_name_or_options.symbolize_keys!
      else
        {:adempiere_name => field_name_or_options}
      end
    
      options[:name] = name
    
      raise ArgumentError, "You must supply a field name."      if options[:name].blank?
      raise ArgumentError, "You must supply an adempiere name." if options[:adempiere_name].blank?
    
      options[:name]           = options[:name].to_sym
      options[:adempiere_name] = options[:adempiere_name].to_sym
    
      self.class.attributes.each do |attribute|
        send "#{attribute}=", options.delete(attribute) unless options[attribute].blank?
      end
    
      raise ArgumentError, "The following options are not allowed: #{options.inspect}" unless options.empty?
    end
  
    def write_methods(object)
      field = self
      object.class_eval do
        eval "def #{field.name}; @attributes[:#{field.name}]; end"
        eval "def #{field.name}=(#{field.name}); @attributes[:#{field.name}] = #{field.name}; end"
      end
    end
    
    def escape attribute
      if /^is/i === adempiere_name.to_s
        if attribute
          'Y'
        else
          'N'
        end
      elsif /date/i === adempiere_name.to_s
        attribute.strftime("%Y-%m-%d %H:%M:%S")
      else
        attribute.to_s
      end
    end
    
    def read_only?
      !! read_only
    end
  end
end