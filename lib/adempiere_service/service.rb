require 'handsoap'

module AdempiereService
  class Service < Handsoap::Service
    endpoint :uri => 'http://adempiere.local:8080/ADInterface/services/ModelADService', :version => 1
    def on_create_document(doc)
      # register namespaces for the request
      doc.alias 'tns', 'http://3e.pl/ADInterface'
    end

    def on_response_document(doc)
      # register namespaces for the response
      doc.add_namespace 'ns', 'http://3e.pl/ADInterface'
    end

    # public methods

    def run_process!
      soap_action = ''
      response = invoke('tns:runProcess', soap_action) do |message|
        raise "TODO"
      end
    end

    def create_data!(options = {})
      options[:table_name]
      options[:row_data]
      request, response = invoke('tns:createData', :soap_action => :none) do |message|
        message.add 'tns:ModelCRUDRequest' do |wrapper|
          wrapper.add 'tns:ModelCRUD' do |crud|
            crud.add 'tns:serviceType', self.class.service_type(:create, options[:table_name])
            crud.add 'tns:DataRow' do |data_row|
              options[:row_data].each do |field, data|
                data_row.add 'tns:field' do |column|
                  column.set_attr 'column', field.adempiere_name
                  column.add 'tns:val', field.escape(data)
                end
              end
            end
          end
          authenticate(wrapper)
        end
      end

      raise_error(response)
      {:record_id => record_id(response), :request => request, :response => response}
    end

    def update_data!
      soap_action = ''
      response = invoke('tns:updateData', soap_action) do |message|
        raise "TODO"
      end
    end

    def read_data!
      soap_action = ''
      response = invoke('tns:readData', soap_action) do |message|
        raise "TODO"
      end
    end

    def get_list
      soap_action = ''
      response = invoke('tns:getList', soap_action) do |message|
        raise "TODO"
      end
    end

    def set_doc_action!(options = {})
      raise ArgumentError, "set_doc_action! requires a :record_id"  unless (options[:record_id].is_a?(Fixnum) && options[:record_id] > 0) || /^[1-9][0-9]*$/ === options[:record_id].to_s
      raise ArgumentError, "set_doc_action! requires a :table_name" if options[:table_name].blank?
      raise ArgumentError, "set_doc_action! requires a :doc_action" unless /^[A-Z]{2}$/ === options[:doc_action].to_s
      
      request, response = invoke('tns:setDocAction', :soap_action => :none) do |message|
        message.add 'tns:ModelSetDocActionRequest' do |wrapper|
          wrapper.add 'tns:ModelSetDocAction' do |doc_action|
            doc_action.add 'tns:recordID', options[:record_id].to_s
            doc_action.add 'tns:serviceType', self.class.service_type(:set_doc, options[:table_name])
            doc_action.add 'tns:docAction', options[:doc_action].to_s
          end
          authenticate(wrapper)
        end
      end
      
      raise_error(response)
      {:record_id => record_id(response), :request => request, :response => response}
    end

    def delete_data!
      soap_action = ''
      response = invoke('tns:deleteData', soap_action) do |message|
        raise "TODO"
      end
    end

    def query_data!
      soap_action = ''
      response = invoke('tns:queryData', soap_action) do |message|
        raise "TODO"
      end
    end
    
    def self.service_type type, table_name
      "#{type}_#{table_name.to_s.split('_')[1..-1].join('_')}".classify
    end

    private
      def dispatch(doc, action)
        [doc, super]
      end
      
      def ns
        { 'ns' => 'http://3e.pl/ADInterface' }
      end
      
      def authenticate message
        parameters = {
          :username     => 'WebService',
          :password     => 'WebService',
          :role_id      => 50004,
          :client_id    => 11,
          :org_id       => 11,
          :warehouse_id => 103,
          :language     => 'en_US',
          :stage        => 9
        }
        message.add 'tns:ADLoginRequest' do |auth|
          auth.add 'tns:user',        AdempiereService.configuration.service.username
          auth.add 'tns:pass',        AdempiereService.configuration.service.password
          auth.add 'tns:RoleID',      AdempiereService.configuration.service.role_id
          auth.add 'tns:ClientID',    AdempiereService.configuration.service.client_id
          auth.add 'tns:OrgID',       AdempiereService.configuration.service.org_id
          auth.add 'tns:WarehouseID', AdempiereService.configuration.service.warehouse_id
          auth.add 'tns:lang',        AdempiereService.configuration.service.language
          auth.add 'tns:stage',       AdempiereService.configuration.service.stage
        end
      end
      
      def raise_error(response)
        if standard_response_has_errors?(response)
          raise AdempiereServiceError, 'Error response received.'
        elsif has_errors? response
          raise ErrorsReturned, errors(response).inspect
        elsif !has_record_id? response
          raise RecordIDNotReturned, ["record id is #{record_id response}", response.inspect].join("\n")
        end
      end
      
      def has_errors?(response)
        not errors(response).empty?
      end
      
      def standard_response_has_errors?(response)
        response.document.xpath(".//ns:StandardResponse[@IsError='true']", ns).length > 0
      end
      
      def errors(response)
        response.document.xpath('ns:Error', ns)
      end
      
      def has_record_id?(response)
        record_id(response) ? record_id(response) > 0 : false
      end
      
      def record_id(response)
        record_id = response.document.xpath('.//ns:StandardResponse[@RecordID]', ns)
        record_id.length > 0 ? record_id.first['RecordID'].to_i : nil
      end
  end
  
  class AdempiereServiceError < StandardError;         end
  class RecordIDNotReturned   < AdempiereServiceError; end
  class ErrorsReturned        < AdempiereServiceError; end
end