module AdempiereService
  class Payment < Base
    table_name :C_Payment
    define_field :document_type_id     => :C_DocType_ID,
                 :bank_account_id      => :C_BankAccount_ID,
                 :business_partner_id  => :C_BPartner_ID,
                 :currency_id          => :C_Currency_ID,
                 :accounting_date      => :DateAcct,
                 :transation_date      => :DateTrx,
                 :tender_type          => :TenderType,
                 :amount               => :PayAmt,
                 :document_status      => [:DocStatus,    {:read_only => true}],
                 :reconciled           => [:IsReconciled, {:read_only => true}]

    include DocProcessor
  end
end