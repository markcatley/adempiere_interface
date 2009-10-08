require 'pg'

module AdempiereService
  class Migrator
    attr_reader :service
    
    def initialize service
      @service = service
    end
    
    def options_hash(options = {})
      hash = {
        :table      => @service.table_name,
        :parameters => [
          {
            :name  => 'TableName',
            :value => @service.table_name
          }
        ],
        :roles => role_ids
      }
      hash[:input_columns]  = service.fields.values.select do |f|
        !f.read_only?
      end.map(&:adempiere_name) if options[:input_columns]
      hash[:output_columns] = service.fields.values.map(&:adempiere_name) if options[:output_columns]
      
      if options.has_key?(:action)
        hash[:type]        = options[:action]
        hash[:parameters] << {:name => 'Action', :value => options[:action]}
      end
      
      hash[:parameters] << {:name => 'DataRow'}  if options[:data_row]
      
      if options[:record_id]
        hash[:parameters] << {:name => 'RecordID'}
        hash[:parameters].last[:value] = options[:record_id] unless options[:record_id] == true
      end
      
      hash
    end
    
    def create_options_hash
      options_hash :action         => :create,
                   :input_columns  => true,
                   :output_columns => true,
                   :data_row       => true,
                   :record_id      => 0
    end
    
    def update_options_hash
      options_hash :action         => :update,
                   :input_columns  => true,
                   :output_columns => true,
                   :data_row       => true,
                   :record_id      => true
    end
    
    def delete_options_hash
      options_hash :action         => :delete,
                   :record_id      => true
    end
    
    def read_options_hash
      options_hash :action         => :read,
                   :output_columns => true,
                   :record_id      => true
    end
    
    # def query_options_hash
    #   options_hash :action         => :query
    # end

    # def list_options_hash
    # end

    # def process_options_hash
    # end

    def set_doc_options_hash
      hash = options_hash :record_id => true
      hash[:type] = :set_doc
      hash[:parameters].select { |p| p[:name] == 'TableName' }.each { |p| p[:name] = 'tableName' }
      hash[:parameters].select { |p| p[:name] == 'RecordID'  }.each { |p| p[:name] = 'recordID'  }
      hash[:parameters] << {:name => 'docAction'}
      hash
    end
    
    def migrate!
      #:query, :list, :process
      [:create, :update, :delete, :read, :set_doc].each do |action|
        webservice = MigratorHelpers::Webservice.new connection, send("#{action}_options_hash")
        webservice.migrate!
      end
    end
    
    def connection
      AdempiereService.configuration.database.connection
    end
    
    def role_ids
      AdempiereService.configuration.other_roles | [AdempiereService.configuration.service.role_id] 
    end
  end
  
  module MigratorHelpers
    module SQLClass
      def standard_columns
        @standard_columns ||= {
          :AD_Client_ID => 11,
          :AD_Org_ID    => 0,
          :Created      => "timestamp '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}'",
          :CreatedBy    => 100,
          :Updated      => "timestamp '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}'",
          :UpdatedBy    => 100,
          :IsActive     => "'Y'"
        }
      end

      def self.included base
        base.class_eval do
          attr_accessor :primary_key
          attr_reader   :connection
        end
      end

      def primary_key_name
        "#{table_name}_id".to_sym
      end

      def new_record?
        primary_key.blank?
      end

      def delete!
        unless new_record?
          connection.execute "DELETE FROM #{table_name}
                              WHERE #{primary_key_name} = #{primary_key} AND
                              AD_Client_ID = #{standard_columns[:AD_Client_ID]} AND
                              AD_Org_ID    = #{standard_columns[:AD_Org_ID]};"
        end
        self.primary_key = nil
      end

      def to_sql params = nil
        params ||= {}
        primary_key = if params.delete :database_filled_primary_key
          {}
        else
          {primary_key_name => "(SELECT COALESCE(MAX(#{primary_key_name}) + 1, 50000) FROM #{table_name})"}
        end
        params = primary_key.merge(to_param).merge(params)

        if new_record?
          command     = 'INSERT INTO'
          assignment  = 'VALUES'
        else
          command     = 'UPDATE'
          command_aux = 'SET'
          assignment  = '='
          where       = "(#{primary_key_name} = #{primary_key})"
        end

        "#{command} #{table_name} #{command_aux} " +
        "(#{params.keys.join(', ')}) #{assignment} (#{params.values.join(', ')}) " +
        (where.nil? ? "" : "WHERE #{where} ") +
        "RETURNING #{primary_key_name} AS PRIMARY_KEY;"
      end

      def exec_sql! params = :none
        sql = params == :none ? to_sql : to_sql(params)
        result = connection.execute sql
        self.primary_key = result[0]['primary_key']
        raise "Primary key not found." if primary_key.blank?
        primary_key
      end

      def exec_child_sql! child_name, params = nil
        exec_sql! params if new_record?
        send(child_name).each do |child|
          child.exec_sql!({primary_key_name => primary_key}.merge(params || {}))
        end
      end
    end

    class Webservice
      include SQLClass

      def initialize(connection, options)
        @connection          = connection
        @type                = options[:type].to_sym
        @table               = options[:table]
        @parmeter_options    = options[:parameters]
        @input_column_names  = options[:input_columns]
        @output_column_names = options[:output_columns]
        @role_ids            = options[:roles]
      end

      def method_name
        case @type
        when :create  then :createData
        when :update  then :updateData
        when :delete  then :deleteData
        when :read    then :readData
        when :query   then :queryData
        when :process then :runProcess
        when :list    then :getList
        when :set_doc then :setDocAction
        end
      end

      def value
        Service.service_type @type, @table
      end

      def name
        value.underscore.humanize
      end

      def description
        name
      end

      def to_param
        ws_webservice_id = 50001
        standard_columns.merge({
          :value                  => "'#{value}'",
          :name                   => "'#{name}'",
          :description            => "'#{description}'",
          :AD_Table_ID            => "(SELECT AD_Table_ID FROM AD_Table
                                      WHERE TableName ILIKE '#{@table}')",
          :WS_Webservice_ID       => ws_webservice_id,
          :WS_WebserviceMethod_ID => "(SELECT WS_WebserviceMethod_ID FROM WS_WebserviceMethod
                                      WHERE VALUE ILIKE '#{method_name}' AND
                                      WS_Webservice_ID = #{ws_webservice_id})"
        })
      end

      def roles
        @roles ||= Role.from_array connection, @role_ids
      end

      def parameters
        @parameters ||= Parameter.from_array connection, @parmeter_options
      end

      def input_columns
        @input_columns ||= InputColumn.from_array connection, @input_column_names, @table
      end

      def output_columns
        @output_columns ||= OutputColumn.from_array connection, @output_column_names, @table
      end

      def new_record?
        if super
          result = connection.execute "SELECT #{primary_key_name} AS PRIMARY_KEY FROM #{table_name}
                                       WHERE VALUE = '#{value}' AND
                                       AD_Client_ID = #{standard_columns[:AD_Client_ID]} AND
                                       AD_Org_ID    = #{standard_columns[:AD_Org_ID]}
                                       LIMIT 1;"
          self.primary_key = result[0]['primary_key'] if result.ntuples > 0
        end
        super
      end

      def table_name
        :WS_WebserviceType
      end

      def delete!
        unless new_record?
          %w(ws_webservice_para ws_webservicefieldinput ws_webservicefieldoutput
              ws_webservicetypeaccess).each do |table_name|
            connection.execute "DELETE FROM #{table_name}
                             WHERE #{primary_key_name} = #{primary_key} AND
                             AD_Client_ID = #{standard_columns[:AD_Client_ID]} AND
                             AD_Org_ID    = #{standard_columns[:AD_Org_ID]};"
          end
        end
        super
      end
      
      def migrate!
        until new_record?
          delete!
        end
        exec_sql!
        exec_child_sql! :parameters
        exec_child_sql! :input_columns
        exec_child_sql! :output_columns
        exec_child_sql! :roles
      end

      class Role
        include SQLClass

        def initialize connection, role_id
          @connection = connection
          @role_id = role_id
        end

        def to_param
          standard_columns.merge :ad_role_id => "'#{@role_id}'", :IsReadWrite => "'Y'"
        end
        
        def to_sql params = :none
          if params == :none
            super({:database_filled_primary_key => true})
          else
            super((params || {}).merge({:database_filled_primary_key => true}))
          end
        end

        def table_name
          :ws_webservicetypeaccess
        end
        
        def primary_key_name
          "md5('' || ad_role_id || ws_webservicetype_id)"
        end

        class << self
          def from_array connection, array
            (array || []).map { |options| self.new connection, options }
          end
        end
      end

      class Parameter
        include SQLClass
        attr_reader :name, :value

        def initialize connection, options
          @connection = connection
          @name = options[:name]
          @value = options[:value] unless options[:value].blank?
        end

        def to_param
          standard_columns.merge({
            :parametername => "'#{@name}'",
            :parametertype => @value.blank? ? "'F'" : "'C'"
          }).merge(@value.blank? ? {} : {:constantvalue => "'#{@value}'"})
        end

        def table_name
          :ws_webservice_para
        end

        class << self
          def from_array connection, array
            (array || []).map { |options| self.new connection, options }
          end
        end
      end

      class Column
        include SQLClass

        def initialize connection, column_name, table_name
          @connection = connection
          @column_name = column_name
          @table_name = table_name
        end

        def to_param
          standard_columns.merge({
            :ad_column_id => "(SELECT ad_column_id FROM AD_COLUMN
                              WHERE columnname ILIKE '#{@column_name}' AND
                              AD_TABLE_ID = (
                                SELECT AD_Table_ID FROM
                                AD_Table WHERE tablename ILIKE '#{@table_name}'
                              ))"
          })
        end

        class << self
          def from_array connection, array, table_name
            (array || []).map { |column_name| self.new connection, column_name, table_name }
          end
        end
      end

      class InputColumn < Column
        def table_name
          :ws_webservicefieldinput
        end
      end

      class OutputColumn < Column
        def table_name
          :ws_webservicefieldoutput
        end
      end
    end
  end
end