module AdempiereService
  class BusinessPartner < Base
    table_name :C_BPartner
    define_field :name              => :Name,
                 :front_end_user_id => :Value,
                 :ird_number        => :TaxID,
                 :vendor            => :IsVendor,
                 :customer          => :IsCustomer,
                 :group_id          => :C_BP_Group_ID,
                 :tax_exempt        => :IsTaxExempt,
                 :alternate_name    => :Name2
  end
end