module Export
  # -
  class EnhancedSurveillanceVaccinePreventableDeathsFile < DeathFileSimple
    FIELDS = %w[
      addrdt icd9_icd10 icd9f_icd10f icd9pv_icd10pv icd9pvf_icd10pvf icd9sc_icd10sc
      icd9scf_icd10scf icd9u_icd10u icd9uf_icd10uf aksnamd fnamd1 fnamd2 namemaid
      snamd nhsno nhsnorss certifer namec namecon cestrssr ctypod hautpod hropod
      cestrss pcdpod podt esttyped nhsind podqual icd_future1 icd_future2 fnamd3
      akfnamd1 pcdr doddy dodmt dodyr ageu1d dobdy dobyr sex lsoar dobmt ctryr ctyr
      cod10r cod10rf codt linen09_lneno10 lineno9f_lneno10f certtype codfft agec
      agecunit ctrypob pobt occdt occtype corareat corcertt doinqt inqcert dor
      postmort hautr inddmt sclasdm sec90dm occfft
    ].freeze

    SPECIAL = {
      aksnamd:  -> { (1..5).collect  { |i| "aksnamd_#{i}" }   },
      nhsno:    -> { (1..5).collect  { |i| "nhsno_#{i}" }     },
      akfnamd1: -> { (1..5).collect  { |i| "akfnamd_1_#{i}" } },
      cod10r:   -> { (1..20).collect { |i| "cod10r_#{i}" }    },
      cod10rf:  -> { (1..20).collect { |i| "cod10rf_#{i}" }   },
      codt:     -> { (1..5).collect  { |i| "codt_#{i}" }      },
      codfft:   -> { (1..65).collect { |i| "codfft_#{i}" }    },
      occfft:   -> { (1..5).collect  { |i| "occfft_#{i}" }    }
    }.freeze

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end

    def match_row?(ppat, _surveillance_code = nil)
      ppat.death_data.dor < '20080101' ? false : super
    end
  end
end
