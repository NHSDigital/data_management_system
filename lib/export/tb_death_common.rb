module Export
  # Export and de-pseudonymise annual all cause deaths in TB format
  # Specification: https://ncr.plan.io/issues/14403
  # Use filter='all' to get all records from a batch (including repeats)
  # or filter='new' to get only new records in a batch (excluding records sent before)
  # or filter='all_nhs' for all records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new records with NHS numbers (excl. such records sent before)
  # Export and de-pseudonymise weekly / monthly / annual tuberculosis (TB) deaths
  # (Common code for all 3 TB extracts: monthly TB deaths, yearly TB deaths, all deaths TB format.)
  class TbDeathCommon < DeathFileSimple
    private

    def fields
      %w[addrdt] +
        (1..5).collect { |i| "aksnamd_#{i}" } +
        (1..5).collect { |i| "akfnamd_1_#{i}" } +
        (1..5).collect { |i| "akfnamd_2_#{i}" } +
        (1..5).collect { |i| "akfnamd_3_#{i}" } +
        %w[aliasd_1 aliasd_2 fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 namemaid
           nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5
           snamd dester pcdpod podqual podt] +
        (1..20).collect { |i| "icd_#{i}" } +
        (1..20).collect { |i| "icdf_#{i}" } +
        (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        %w[icdsc icdscf icdu icduf
           pcdr doddy dodmt dodyr dobdy dobmt dobyr sex] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
        %w[mbisid] +
        (1..20).collect { |i| "cod10r_#{i}" } +
        (1..20).collect { |i| "cod10rf_#{i}" } +
        (1..5).collect { |i| "codt_#{i}" } +
        %w[agec agecunit dor] +
        (1..65).collect { |i| "codfft_#{i}" } +
        %w[cestrss corareat corcertt ctrypob namec occdt occfft_1 occfft_2 occfft_3 occfft_4
           occtype pobt postmort]
    end
  end
end
