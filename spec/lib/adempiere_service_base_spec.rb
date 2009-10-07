require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))

describe AdempiereService::Base do
  before :all do
    @clean_subclass ||= Class.new AdempiereService::Base
    @product_class  ||= Proc.new do
      product_class = Class.new AdempiereService::Base
      product_class.table_name :M_Product
      product_class.define_fields :name => :name,
                                   :cost => :amt
      product_class
    end.call
  end

  it 'should have fields' do
    example = @clean_subclass.clone
    example.fields = :unique_symbol
    example.fields.should == :unique_symbol
  end
  
  it 'should have table' do
    example = @clean_subclass.clone
    example.table_name :unique_symbol
    example.table_name.should == :unique_symbol
  end
  
  it 'should be able to set table name and that should assign table name and id name' do
    example = @clean_subclass.clone
    example.table_name :foo
    example.table_name.should == :foo
    example.id_name.should    == :foo_ID
  end
  
  it 'should create and store a field object when a field is defined' do
    example = @clean_subclass.clone
    AdempiereService::Field.should_receive(:new).with(:ruby, :adempiere).and_return(:first_mocked_object)
    AdempiereService::Field.should_receive(:new).with(:foo,  :bar      ).and_return(:second_mocked_object)
    AdempiereService::Field.should_receive(:new).with(:blah, :baz      ).and_return(:third_mocked_object)
    Symbol.class_eval { def write_methods(*args); nil; end }
    example.define_fields :ruby => :adempiere, :foo => :bar
    example.fields.should     include(:ruby => :first_mocked_object,
                                      :foo  => :second_mocked_object)
    example.fields.should_not include(:blah => :third_mocked_object)
    
    example.define_fields :blah => :baz
    example.fields.should include(:ruby => :first_mocked_object,
                                  :foo  => :second_mocked_object,
                                  :blah => :third_mocked_object)
    Symbol.class_eval { remove_method :write_methods }
  end
  
  it 'should set attributes on instantiation' do
    product = @product_class.new(:name => 'Shoe', :cost => '7.50'.to_d)
    product.name.should == 'Shoe'
    product.cost.should == '7.50'.to_d
  end
  
  it 'should call service on saving a new record' do
    product = @product_class.new :name => 'Shoe', :cost => '7.50'.to_d
    mock_service_with_create_response(@product_class)
    
    product.save.should be_true
    product.id.should == 1000005
  end
  
  it 'should send fields with the request' do
    product = @product_class.new :name => 'Shoe', :cost => '7.50'.to_d
    mock_service_with_create_response(@product_class)
    product.save!
    
    doc = Nokogiri::XML(product.last_request.to_s)
    ns = {'ns' => 'http://3e.pl/ADInterface'}
    model_crud_xpath = './/ns:createData/ns:ModelCRUDRequest/ns:ModelCRUD'
    field_xpath   = "#{model_crud_xpath}/ns:DataRow/ns:field"
    doc.xpath("#{model_crud_xpath}/ns:serviceType", ns).map(&:content).should == ['CreateProduct']
    doc.xpath("#{field_xpath}[@column='name']/ns:val", ns).map(&:content).should == ['Shoe']
    doc.xpath("#{field_xpath}[@column='amt']/ns:val", ns).map(&:content).map(&:to_d).should == ['7.5'.to_d]
  end
  
  it 'should send authentication with request' do
    product = @product_class.new
    mock_service_with_create_response(@product_class)
    product.save!
    
    doc = Nokogiri::XML(product.last_request.to_s)
    ns = {'ns' => 'http://3e.pl/ADInterface'}
    authentication_xpath = './/ns:createData/ns:ModelCRUDRequest/ns:ADLoginRequest'
    doc.xpath("#{authentication_xpath}/ns:user", ns).map(&:content).should        == ['WebService']
    doc.xpath("#{authentication_xpath}/ns:pass", ns).map(&:content).should        == ['WebService']
    doc.xpath("#{authentication_xpath}/ns:lang", ns).map(&:content).should        == ['en_US']
    doc.xpath("#{authentication_xpath}/ns:ClientID", ns).map(&:content).should    == ['11']
    doc.xpath("#{authentication_xpath}/ns:OrgID", ns).map(&:content).should       == ['11']
    doc.xpath("#{authentication_xpath}/ns:RoleID", ns).map(&:content).should      == ['50004']
    doc.xpath("#{authentication_xpath}/ns:WarehouseID", ns).map(&:content).should == ['103']
    doc.xpath("#{authentication_xpath}/ns:stage", ns).map(&:content).should       == ['9']
  end
  
  def mock_service_with_create_response(klass)
    klass.service.instance.
      should_receive(:send_http_request).
      and_return(
        Handsoap::Http.parse_http_part(
          {},
          %q{
            <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                           xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
               <soap:Body>
                  <ns1:createDataResponse xmlns:ns1="http://3e.pl/ADInterface">
                     <StandardResponse RecordID="1000005" xmlns="http://3e.pl/ADInterface"/>
                  </ns1:createDataResponse>
               </soap:Body>
            </soap:Envelope>
          },
          200,
          'text/xml'
        ))
  end
end