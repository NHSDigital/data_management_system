module OdrDataImporter
  module ReleaseImporter
    def create_release(application, attrs)
      application.releases.create!(
        reference: attrs['release_ref'],
        invoice_requested_date: attrs['invoice_requested_date'],
        invoice_sent_date: attrs['invoice_sent_date'],
        phe_invoice_number: attrs['phe_invoice_number'],
        po_number: attrs['po_number'],
        ndg_opt_out_processed_date: attrs['ndg_opt_out_processed_date'],
        cprd_reference: attrs['cprd_reference'],
        actual_cost: attrs['actual_cost'],
        vat_reg: proposition_mapping[attrs['vat_reg']&.downcase],
        income_received: proposition_mapping[attrs['income_received']&.downcase],
        drr_no: attrs['drr_qa'],
        cost_recovery_applied: proposition_mapping[attrs['cost_recovery_applied']&.downcase],
        individual_to_release: attrs['individual_to_release'],
        release_date: attrs['release_date']
      ) unless @test_mode
    end

    def proposition_mapping
      {
        'true'           => 'Y',
        'yes'            => 'Y',
        'false'          => 'N',
        'no'             => 'N',
        'not applicable' => 'NA'
      }
    end
  end
end
