module AdempiereService
  class BankStatementLine < Base
    table_name :C_BankStatementLine
    define_field :business_partner_id     => :C_BPartner_ID,
                 :bank_statement_id       => :C_BankStatement_ID,
                 :charge_id               => :C_Charge_ID,
                 :currency_id             => :C_Currency_ID,
                 :invoice_id              => :C_Invoice_ID,
                 :payment_id              => :C_Payment_ID,
                 :charge_amount           => :ChargeAmt,
                 :accounting_date         => :DateAcct,
                 :description             => :Description,
                 :eft_amount              => :EftAmt,
                 :eft_check_number        => :EftCheckNo,
                 :eft_currency            => :EftCurrency,
                 :eft_memo                => :EftMemo,
                 :eft_payee               => :EftPayee,
                 :eft_payee_account       => :EftPayeeAccount,
                 :eft_reference           => :EftReference,
                 :eft_statement_line_date => :EftStatementLineDate,
                 :eft_transaction_id      => :EftTrxID,
                 :eft_transaction_type    => :EftTrxType,
                 :eft_date_effective      => :EftValutaDate,
                 :interest_amount         => :InterestAmt,
                 :manual                  => :IsManual,
                 :reversal                => :IsReversal,
                 :line_number             => :Line,
                 :memo                    => :Memo,
                 :reference_number        => :ReferenceNo,
                 :statement_line_date     => :StatementLineDate,
                 :statement_amount        => :StmtAmt,
                 :transaction_amount      => :TrxAmt,
                 :date_effective          => :ValutaDate

    include DocProcessor

    def amount= amount
      self.charge_amount = self.interest_amount = 0
      self.statement_amount = self.transaction_amount = self.eft_amount = amount
    end
    
    def date= date
      self.statement_line_date = self.eft_statement_line_date = self.eft_date_effective =
        self.date_effective = self.accounting_date = date
    end
  end
end