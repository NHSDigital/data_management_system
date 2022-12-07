module Export
  # Export and de-pseudonymise rare diseases extract for analysis server
  # Specification in plan.io #14702:
  # Initially to be filtered against cases identified from the data lake
  # The regular rare disease extract for CARA data loading is in lib/export/cancer_death_common.rb
  # Filter options:
  # cd: New cancer deaths (only cancer causes) including patients with previous non-cancer causes
  #     who are now cancer deaths.
  # ncd: New non-cancer deaths (only non-cancer causes)
  # new: All new coded cancer and non-cancer deaths
  # all: Everything, including repeats of the same patient, and patients with no causes of death
  # cara: New congenital anomaly deaths, cf. https://ncr.plan.io/issues/15123
  # cara_all: All congenital anomaly deaths
  # rd: New rare disease deaths, cf. https://ncr.plan.io/issues/14947
  # rd_all: All rare disease deaths
  class RareDiseaseDeathsFile < CancerDeathCommon
    # TODO: Make CancerDeathCommon override SimpleCsv

    # List of MBIS death fields needed (for NHSD migration)
    # Copy of fields - ['patientid'], and replacing 'sex_statistical' with 'sex'
    RAW_FIELDS_USED = (
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
           postmort retindm sex snamd]
    ).freeze

    def initialize(filename, e_type, ppats, filter, ppatid_rowids: nil)
      super
      @fields = fields
    end

    private

    def header_rows
      [@fields.collect(&:upcase)]
    end

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: false }
    end

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

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      val = super(ppat, field)
      val = nil if val == '' # Remove unnecessary double quoted fields in output
      val
    end
  end
end
