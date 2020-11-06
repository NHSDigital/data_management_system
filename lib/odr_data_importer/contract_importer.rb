module OdrDataImporter
  module ContractImporter
    def create_contract(application, attrs)
      # TODO:
      # data_sharing_contract_ref: nil,
      # dra_start: nil,
      # dra_end: nil,
      # contract_type: nil,
      # contract_status: nil,

      application.contracts.create!(
        reference: attrs['contract_ref'],
        contract_sent_date: attrs['contract_sent_date'],
        contract_version: attrs['contract_version'],
        contract_start_date: attrs['contract_start_date'],
        contract_end_date: attrs['contract_end_date'],
        contract_returned_date: attrs['contract_returned_date'],
        contract_executed_date: attrs['contract_executed_date'],
        advisory_letter_date: attrs['advisory_letter_date'],
        destruction_form_received_date: attrs['destruction_form_received_date']
      ) unless @test_mode
    end
  end
end
