module Export
  # Export and de-pseudonymise rare diseases extract for analysis server
  # Specification in plan.io #14702:
  # Initially to be filtered against cases identified from the data lake
  class RareDiseaseDeathsFile < DeathFileSimple
    SURVEILLANCE_PATTERN = /
       \A(E830|M313|M301|M317|G12|Q87|Q80|Q81|Q85|Q86|Q87|Q78|Q928|D821|D57|D56)
    /x

    def initialize(filename, e_type, ppats, filter, ppatid_rowids: nil)
      if filter.start_with?('rd_') # Allow 'rd_' prefix to filter to limit to rare diseases
        filter = filter.sub('rd_', '')
        @pattern = SURVEILLANCE_PATTERN
      else
        @pattern = nil
      end
      super(filename, e_type, ppats, filter, ppatid_rowids: ppatid_rowids)
      # Fields to check for matches
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w[icduf]
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w[icdu]
    end

    private

    # Fields to extract
    def fields
      %w[addrdt agec agecunit ageu1d] +
        (1..5).collect { |i| "akfnamd_1_#{i}" } +
        (1..5).collect { |i| "akfnamd_2_#{i}" } +
        (1..5).collect { |i| "akfnamd_3_#{i}" } +
        (1..5).collect { |i| "akfndi_#{i}" } +
        (1..5).collect { |i| "aksnamd_#{i}" } +
        %w[aliasd_1 aliasd_2 certifer certtype ceststay] +
        (1..20).collect { |i| "cod10r_#{i}" } +
        (1..20).collect { |i| "cod10rf_#{i}" } +
        (1..65).collect { |i| "codfft_#{i}" } +
        (1..5).collect { |i| "codt_#{i}" } +
        %w[corareat corcertt ctrypob ctryr ctypod dobdy dobmt dobyr doddy dodmt dodyr
           doinqt dor empsecdm esttyped fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2] +
        (1..20).collect { |i| "icd_#{i}" } +
        (1..20).collect { |i| "icdf_#{i}" } +
        (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
        %w[icdsc icdscf icdu icduf inddmt inqcert] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
        %w[mbisid namec namecon namem namemaid nhsind nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5
           occdt occfft_1 occfft_2 occfft_3 occfft_4 occhft occmt pcdpod pcdr pobt podt
           postmort retindm sex_statistical snamd] +
        %w[patientid] # Matched record id
    end

    def match_row?(ppat, _surveillance_code = nil)
      # TODO: Refactor with match_row? in DeathFileSimple
      if @pattern
        icd_fields = @icd_fields_f
        # Check only final codes, if any present, otherwise provisional codes
        icd_fields = @icd_fields if icd_fields.none? { |f| ppat.death_data.send(f).present? }
        return false if icd_fields.none? { |f| ppat.death_data.send(f) =~ @pattern }
      end
      super
    end
  end
end
