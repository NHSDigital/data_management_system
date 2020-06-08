module Export
  # Export and de-pseudonymise annual Hepatitis death extract
  # Specification in plan.io #11226:
  # Immunisation team require all deaths regardless of year, location or cause of death.
  class HepatitisDeathsFile < DeathFileSimple
    private

    # Fields to extract
    def fields
      %w[fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 namemaid
         nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5 snamd ctydpod pcdpod] +
        (1..20).collect { |i| "icd_#{i}" } +
        (1..20).collect { |i| "icdf_#{i}" } +
        (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        %w[icdsc icdscf icdu icduf] +
        (1..5).collect { |i| "aksnamd_#{i}" } +
        (1..5).collect { |i| "akfnamd_1_#{i}" } +
        (1..5).collect { |i| "akfnamd_2_#{i}" } +
        (1..5).collect { |i| "akfnamd_3_#{i}" } +
        (1..5).collect { |i| "akfndi_#{i}" } +
        %w[aliasd_1 aliasd_2 ctypod pcdr doddy dodmt dodyr
         dobdy dobmt dobyr sex_statistical mbisid codt_1 codt_2 codt_3 codt_4 codt_5]
    end
  end
end
