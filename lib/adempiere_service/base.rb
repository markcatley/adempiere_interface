module AdempiereService
  class Base
    attr_reader :id, :attributes, :last_request, :last_response, :errors
  
    def initialize(attributes = {})
      @attributes = {}
      
      attributes.symbolize_keys!
      self.class.fields.each do |field_name, field|
        self.send "#{field_name}=", attributes[field_name]
      end
    end
    
    def save
      begin
        save!
      rescue AdempiereService::AdempiereServiceError => e
        @errors = e.inspect
        false
      end
    end
    
    def save!
      new_record? ? create! : update!
    end
    
    def new_record?
      id.blank? || id.zero?
    end
    
    class << self
      attr_accessor :fields
      def table_name(table_name = :dont_set)
        unless table_name == :dont_set
          @table_name = table_name
          id_name
        end
        
        @table_name
      end
    
      def id_name(id_name = :dont_set)
        @id_name   = id_name.to_sym unless id_name == :dont_set
        id_name_was = @id_name
        @id_name ||= "#{table_name}_ID".to_sym if table_name
        if ((!id_name_was && @id_name) || id_name != :dont_set) && self.fields &&
           !self.fields.select { |field_name, field| field.adempiere_name.to_s.downcase == @id_name.to_s.downcase }.empty?
          raise ArgumentError, 'You cannot define the id_name as a field.'
        end
        
        @id_name
      end
    
      def define_field(fields)
        self.fields ||= {}
        fields.each do |ruby_name, adempiere_name|
          raise ArgumentError, 'You cannot define the id_name as a field.' if adempiere_name.to_s.downcase == id_name.to_s.downcase
          self.fields[ruby_name.to_sym] = Field.new(ruby_name, adempiere_name)
          self.fields[ruby_name.to_sym].write_methods(self)
        end
      end
      alias_method :define_fields, :define_field
      
      def service
        Service
      end
      
      def create! *args
        new(*args).save!
      end
    end
    
    private
      def create!
        response = self.class.service.create_data!({
          :table_name => self.class.table_name,
          :row_data   => self.class.fields.inject({}) do |memo, field|
                           field_name, field = *field
                           memo[field] = attributes[field_name]
                           memo
                         end.reject do |field, data|
                           data.blank?
                         end
        })
        @id = response[:record_id]
        @last_request  = response[:request]
        @last_response = response[:response]
        self
      end
      
      def update!
        raise 'AdempiereService::Base.update! not yet implimented.'
      end
  end
end