module Export
  # Export and de-pseudonymise congenital anomalies (CARA) births extract
  # Specification in plan.io #18114
  class CongenitalAnomaliesBirthsFile < BirthFileSimple
    private

    # Fields to extract
    def fields
      (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        %w[fnamch1 fnamch2 fnamch3 fnamchx_1 snamch nhsno addrmt cestrss nhsind pcdpob pobt
           esttypeb namemaid dobm_iso dob_iso pcdrm fnamm_1 fnammx_1 snamm
           birthwgt multbth multtype sbind] +
        (1..20).collect { |i| "cod10r_#{i}" } +
        %w[deathlab wigwo10 sex empsecm empstm soc2km soc90m gestatn] +
        (1..5).collect { |i| "codfft_#{i}" } +
        %w[patientid] # Matched record id
    end
  end
end
