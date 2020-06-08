module Export
  # Export and de-pseudonymise Sloane Atypia Audit follow up extract
  # Specification: https://ncr.plan.io/issues/17525
  # "Sloane atypia audit" plan.io #17525
  # All-cause death registrations
  class SloaneAtypiaFile < DeathFileSimple
    private

    def fields
      %w[patientid] + (1..20).collect { |i| "icd_icdf_#{i}" } +
        %w[icdsc_icdscf icdu_icduf nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5 nhsnorss ccgpod ccg9pod
           doddy dodmt dodyr] + (1..65).collect { |i| "codfft_#{i}" }
    end

    # Return only new rows, and ignore rows without NHS numbers
    def match_row?(ppat, _surveillance_code = nil)
      ppat.unlock_demographics('', '', '', :export)
      ppat.demographics['nhsnumber'].present? && !already_extracted?(ppat)
    end
  end
end
