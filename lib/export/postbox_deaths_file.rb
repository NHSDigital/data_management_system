module Export
  # Export and de-pseudonymise POSTBOx extract (Patient Outcomes from Second
  # film-readers and Test threshold relaxation in Breast screening: Observational evaluation)
  # Specification: https://ncr.plan.io/issues/22443
  # All-cause death registrations
  class PostboxDeathsFile < DeathFileSimple
    private

    def fields
      %w[patientid] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
        (1..20).collect { |i| "cod10r_#{i}" } +
        (1..20).collect { |i| "cod10rf_#{i}" } +
        (1..20).collect { |i| "multiple_cause_code_#{i}" } +
        %w[ons_code1a ons_code1b ons_code1c ons_code2 ons_code icdu_icduf] +
        %w[dobdy dobmt dobyr doddy dodmt dodyr]
    end

    # Return only new rows, and ignore rows without NHS numbers
    def match_row?(ppat, _surveillance_code = nil)
      ppat.unlock_demographics('', '', '', :export)
      ppat.demographics['nhsnumber'].present? && !already_extracted?(ppat)
    end
  end
end
