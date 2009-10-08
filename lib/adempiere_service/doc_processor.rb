module AdempiereService
  module DocProcessor
    def complete!
      doc_action! 'CO'
    end
  
    def void!
      doc_action! 'VO'
    end
  
    private
      def doc_action!(action)
        self.class.service.set_doc_action!({
          :record_id  => id,
          :table_name => self.class.table_name,
          :doc_action => action
        })
      end
  end
end