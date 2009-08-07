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
            crud.add 'tns:serviceType', service_type(:create, options[:table_name])
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

      if has_errors?(response) || !has_record_id?(response)
        raise_error(response)
      end
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

    def set_doc_action!
      soap_action = ''
      response = invoke('tns:setDocAction', soap_action) do |message|
        raise "TODO"
      end
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

    private
      def dispatch(doc, action)
        [doc, super]
      end
      
      def ns
        { 'ns' => 'http://3e.pl/ADInterface' }
      end
      
      def service_type type, table_name
        "#{type}_#{table_name.to_s.split('_')[1..-1].join('_')}".classify
      end
      
      def authenticate message
        message.add 'tns:ADLoginRequest' do |auth|
          auth.add 'tns:user',        'WebService'
          auth.add 'tns:pass',        'WebService'
          auth.add 'tns:RoleID',      50004
          auth.add 'tns:ClientID',    11
          auth.add 'tns:OrgID',       11
          auth.add 'tns:WarehouseID', 103
          auth.add 'tns:lang',        'en_US'
          auth.add 'tns:stage',       9
        end
      end
      
      def raise_error(response)
        if has_errors? response
          raise ErrorsReturned, errors(response)
        elsif !has_record_id? response
          raise RecordIDNotReturned, ["record id is #{record_id response}", response.inspect].join("\n")
        end
      end
      
      def has_errors?(response)
        not errors(response).empty?
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