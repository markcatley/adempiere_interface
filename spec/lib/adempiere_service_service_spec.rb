require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))

describe AdempiereService::Service do
  before(:all) { @ns = {'ns' => 'http://3e.pl/ADInterface'} }

  describe :set_doc_action! do
    before(:all) do
      @valid_options_hash = {:record_id => 1000000, :table_name => 'C_Payment', :doc_action => 'CO'}
      @request_prefix        = 'ns:setDocAction/ns:ModelSetDocActionRequest'
    end
    
    describe :sample_response do
      before(:all) do
        mock_service_with_set_doc_action_response :record_id => @valid_options_hash[:record_id]
        @result = AdempiereService::Service.set_doc_action! @valid_options_hash
        @doc = Nokogiri::XML(@result[:request].to_s)
      end
      
      it 'should produce hash with correct keys' do
        @result.keys.should include(:record_id, :request, :response)
      end
      
      it 'should send authentication data' do
        should_send_authentication_data(@doc, @request_prefix)
      end
      
      it 'should send recordID' do
        @doc.xpath(".//#{@request_prefix}/ns:ModelSetDocAction/ns:recordID", @ns).map(&:content).
          should == [@valid_options_hash[:record_id].to_s]
      end
      
      it 'should send serviceType' do
        @doc.xpath(".//#{@request_prefix}/ns:ModelSetDocAction/ns:serviceType", @ns).map(&:content).
          should == ['SetDocPayment']
      end
      
      it 'should send docAction' do
        @doc.xpath(".//#{@request_prefix}/ns:ModelSetDocAction/ns:docAction", @ns).map(&:content).
          should == [@valid_options_hash[:doc_action].to_s]
      end
    end
    
    describe :required_attributes do
      it 'should require recordID' do
        lambda do
          AdempiereService::Service.set_doc_action! @valid_options_hash.reject { |k, v| k == :record_id }
        end.should raise_error(ArgumentError) { |error| /:record_id/.should === error.message }
      end

      it 'should require table_name' do
        lambda do
          AdempiereService::Service.set_doc_action! @valid_options_hash.reject { |k, v| k == :table_name }
        end.should raise_error(ArgumentError) { |error| /:table_name/.should === error.message }
      end
      
      it 'should require docAction' do
        lambda do
          AdempiereService::Service.set_doc_action! @valid_options_hash.reject { |k, v| k == :doc_action }
        end.should raise_error(ArgumentError) { |error| /:doc_action/.should === error.message }
      end
    end
    
    it "should handle response errors correctly" do
      mock_service_with_set_doc_action_response :record_id => @valid_options_hash[:record_id], :error => true
      lambda do
        AdempiereService::Service.set_doc_action! @valid_options_hash
      end.should raise_error
    end
  end
  
  def should_send_authentication_data(doc, prefix)
    authentication_xpath = ".//#{prefix}/ns:ADLoginRequest"
    doc.xpath("#{authentication_xpath}/ns:user",        @ns).map(&:content).should == ['WebService']
    doc.xpath("#{authentication_xpath}/ns:pass",        @ns).map(&:content).should == ['WebService']
    doc.xpath("#{authentication_xpath}/ns:lang",        @ns).map(&:content).should == ['en_US']
    doc.xpath("#{authentication_xpath}/ns:ClientID",    @ns).map(&:content).should == ['11']
    doc.xpath("#{authentication_xpath}/ns:OrgID",       @ns).map(&:content).should == ['11']
    doc.xpath("#{authentication_xpath}/ns:RoleID",      @ns).map(&:content).should == ['50004']
    doc.xpath("#{authentication_xpath}/ns:WarehouseID", @ns).map(&:content).should == ['103']
    doc.xpath("#{authentication_xpath}/ns:stage",       @ns).map(&:content).should == ['9']
  end
  
  def mock_service_with_set_doc_action_response(options = {})
    options[:error]       = false unless options.has_key? :error
    options[:http_status] = 200   unless options.has_key? :http_status

    mock_service_with_response(options[:http_status], %Q{
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <soap:Body>
            <ns1:setDocActionResponse xmlns:ns1="http://3e.pl/ADInterface">
               <StandardResponse RecordID="#{options[:record_id]}" IsError="#{options[:error]}" xmlns="http://3e.pl/ADInterface"/>
            </ns1:setDocActionResponse>
         </soap:Body>
      </soap:Envelope>
    })
  end
  
  def mock_service_with_response(status, message)
    AdempiereService::Service.instance.
      should_receive(:send_http_request).
      and_return(
        Handsoap::Http.parse_http_part(
          {},
          message,
          status,
          'text/xml'
        ))
  end
end