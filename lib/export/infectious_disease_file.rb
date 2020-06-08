module Export
  # Export and de-pseudonymise annual infectious disease extract
  # Specification: https://ncr.plan.io/issues/9856#note-2,
  # "MR1000 HPA and ONS MRSA Mortality Annual extract" plan.io #9856
  # All-cause death registrations
  # (ONS used to send a different format historically; an interim version of the code was
  #  committed, for specification file: "Infectious Disease linked to Mortlity Records MR1000.pdf")
  class InfectiousDiseaseFile < DeathFileSimple
    private

    def fields
      %w[addrdt] +
        (1..5).collect { |i| "aksnamd_#{i}" } +
        (1..5).collect { |i| "akfnamd_1_#{i}" } +
        (1..5).collect { |i| "akfnamd_2_#{i}" } +
        (1..5).collect { |i| "akfnamd_3_#{i}" } +
        (1..5).collect { |i| "akfndi_#{i}" } +
        %w[aliasd_1 aliasd_2 fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 namemaid
           nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5 nhsnorss
           snamd namehf namem cestrssr ccgpod cestrss ctydpod ctypod dester esttyped
           nhsind pcdpod ploacc10 podqual podt ccg9pod] +
        (1..20).collect { |i| "icd_#{i}" } +
        (1..20).collect { |i| "icdf_#{i}" } +
        (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        %w[icdsc icdscf icdu icduf icdfuture1 icdfuture2 loapod lsoapod pcdr doddy dodmt
           dodyr ageu1d dobdy dobmt dobyr loar lsoar sex agecs occ90dm occ90hf] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
        %w[mbism204id ledrid ceststay] +
        (1..20).collect { |i| "cod10r_#{i}" } +
        (1..20).collect { |i| "cod10rf_#{i}" } +
        (1..5).collect { |i| "codt_#{i}" } +
        %w[wigwo10 wigwo10f agec agecunit ccgr ctrypob ctryr ctydr ctyr gorr hautr hror
           marstat occdt occfft_1 occfft_2 occfft_3 occfft_4 occtype pobt wardr emprssdm
           emprsshf empsecdm empsechf empstdm empsthf inddmt indhft occhft occmt retindm
           retindhf sclasdm sclashf sec90dm sec90hf seccatdm seccathf secclrdm secclrhf
           soc2kdm soc2khf soc90dm soc90hf certtype corareat corcertt doinqt dor inqcert
           postmort] +
        (1..5).collect { |i| "codfft_#{i}" } +
        %w[ccg9r gor9r ward9r]
    end
  end
end
