module Export
  # Plan.io 16065 / Project ID 72
  # NOTE: Requires linkage file
  class LinkingHepCasesDeathFile < DeathFileSimple
    FIELDS = %w[
      nhsno pcdpod podt icd9f_icd10f icd9u_icd10u addrdt icd9scf_icd10scf icd9uf_icd10uf
      icd9_icd10 doddy dodmt dodyr dobdy dobmt sex dobyr cod10r cod10rf codt agec dor
      codfft occdt occfft pobt ctryr
    ].freeze

    SPECIAL = {
      nhsno:   -> { (1..5).collect  { |i| "nhsno_#{i}" }   },
      cod10r:  -> { (1..20).collect { |i| "cod10r_#{i}" }  },
      cod10rf: -> { (1..20).collect { |i| "cod10rf_#{i}" } },
      codt:    -> { (1..5).collect  { |i| "codt_#{i}" }    },
      codfft:  -> { (1..65).collect { |i| "codfft_#{i}" }  },
      occfft:  -> { (1..5).collect  { |i| "occfft_#{i}" }  }
    }.freeze

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end
  end
end
