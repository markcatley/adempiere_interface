module AdempiereService
  class BankStatement < Base
    table_name :C_BankStatement
    define_field :bank_account_id         => :C_BankAccount_ID,
                 :beginning_balance       => :BeginningBalance,
                 :description             => :Description,
                 :eft_statement_date      => :EftStatementDate,
                 :eft_statement_reference => :EftStatementReference,
                 :ending_balance          => :EndingBalance,
                 :name                    => :Name,
                 :statement_date          => :StatementDate,
                 :statement_difference    => :StatementDifference,
                 :approved                => :IsApproved,
                 :manual                  => :IsManual,
                 :document_status         => [:DocStatus, {:read_only => true}]

    include DocProcessor
  end
end