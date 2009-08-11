require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))

describe AdempiereService::Field do
  before :each do
    @name           = :business_partner_id
    @adempiere_name = :C_BPartner_ID
    @options_hash   = {:adempiere_name => @adempiere_name}
    @arguments      = [@name, @adempiere_name]
  end
  
  it 'should assign name and adempiere name on new without options' do
    field = AdempiereService::Field.new @name, @adempiere_name
    field.name.should == @name
    field.adempiere_name.should == @adempiere_name
  end

  it 'should assign name and adempiere name on new with options' do
    field = AdempiereService::Field.new @name, :adempiere_name => @adempiere_name
    field.name.should == @name
    field.adempiere_name.should ==  @adempiere_name
  end
  
  it 'should raise a ArgumentError if intialized a blank ruby_name or adempiere_name' do
    lambda { AdempiereService::Field.new '', @adempiere_name }.should raise_error(ArgumentError) do |error|
      error.message.should == 'You must supply a field name.'
    end
    
    lambda { AdempiereService::Field.new @name, nil }.should raise_error(ArgumentError) do |error|
      error.message.should == 'You must supply an adempiere name.'
    end
  end
  
  it 'should raise a ArgumentError if bad options are supplied' do
    lambda { AdempiereService::Field.new @name,
                                         @options_hash.merge({
                                           :foozemwhatzit => :blah
                                          }) }.should raise_error(ArgumentError) do |error|
      error.message.should == 'The following options are not allowed: {:foozemwhatzit=>:blah}'
    end
  end
  
  it 'should coerse name and adempiere name into symbols' do
    field = AdempiereService::Field.new @name.to_s, @adempiere_name.to_s
    field.name          .should == @name.to_sym
    field.adempiere_name.should == @adempiere_name.to_sym
  end
  
  it 'write accessors onto an object' do
    field = AdempiereService::Field.new *@arguments
    object = Object.new
    field.write_methods object
    object.methods.map(&:to_sym).should include(@name, "#{@name}=".to_sym)
    
    object.instance_variable_set :@attributes, {}
    object.business_partner_id = :blah
    object.instance_variable_get(:@attributes)[@name].should == :blah
    
    object.instance_variable_get(:@attributes)[@name] = :foo
    object.business_partner_id.should == :foo
  end
end