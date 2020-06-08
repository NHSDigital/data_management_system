module Export
  # Export and de-pseudonymise National Registry for Radiation Workers follow up extract
  # Specification: https://ncr.plan.io/issues/13494
  # "National Registry for Radiation Workers (NRRW) follow up cohort study" plan.io #13494
  # All-cause death registrations
  class RadiationWorkersFile < DeathFileSimple
    private

    def fields
      %w[patientid addrdt aliasd_1 aliasd_2 fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 namemaid
           nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5 snamd] +
        (1..20).collect { |i| "icd_icdf_#{i}" } +
        %w[icdu_icduf pcdpod podt doddy dodmt dodyr dobdy dobmt dobyr sex pcdr] +
        (1..5).collect { |i| "codt_#{i}" } +
        %w[sclasdm sec90dm occdt occfft_1 occfft_2 occfft_3 occfft_4 pobt seccatdm secclrdm]
    end

    # Return only new rows, and ignore rows without NHS numbers
    def match_row?(ppat, _surveillance_code = nil)
      ppat.unlock_demographics('', '', '', :export)
      ppat.demographics['nhsnumber'].present? && !already_extracted?(ppat)
    end
  end
end
