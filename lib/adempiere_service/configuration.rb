require 'yaml'

module AdempiereService
  def self.configuration
    @configuration ||= Configuration.load
  end
  
  class Configuration
    attr_reader :service, :database, :other_roles
      
    def << conf
      conf.symbolize_keys!
      @service     ||= Service.new
      @database    ||= Database.new
      @other_roles ||= Set.new
      @service     <<  conf[:service_authentication]  if conf.has_key? :service_authentication
      @database    <<  conf[:database_authentication] if conf.has_key? :database_authentication
      @other_roles  |= conf[:other_roles]             if conf.has_key? :other_roles
      self
    end
    
    class << self
      def load
        yml_file = if const_defined? :RAILS_ROOT
          File.expand_path(File.join(RAILS_ROOT, 'config', 'adempiere_service.yml'))
          env = const_get :RAILS_ENV
        else
          File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'adempiere_service.yml'))
        end
        
        options = YAML.load_file(yml_file)
        options = options[env] if env
        
        Configuration.new << options
      end
    end
    
    class Service
      attr_accessor :username,  :password, :role_id,
                    :client_id, :org_id,   :warehouse_id,
                    :language,  :stage
      
      def initialize
        self.language = 'en_US'
        self.stage    = 9
      end
      
      def << options
        options.symbolize_keys!
        
        options.each do |key, value|
          send "#{key}=", value
        end
      end
    end
    
    class Database
      attr_accessor :host, :database, :username, :password
      
      def initialize
        self.host     = 'localhost'
        self.database = 'adempiere'
        self.username = 'adempiere'
        self.password = 'adempiere'
      end
      
      def << options
        options.symbolize_keys!
        
        options.each do |key, value|
          send "#{key}=", value
        end
      end
      
      def connection
        @connection ||= PGconn.new({
          :host     => host,
          :dbname   => database,
          :user     => username,
          :password => password
        })
      end
    end
  end
end