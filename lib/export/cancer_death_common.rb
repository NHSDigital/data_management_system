module Export
  # Export and de-pseudonymise weekly cancer death data
  # (Common code for old fixed-width and new CSV extracts)
  # Specification file: "Cancer Deaths Specification 03-15 2008.docx"
  # Filter options:
  # cd: New cancer deaths (only cancer causes) including patients with previous non-cancer causes
  #     who are now cancer deaths.
  # ncd: New non-cancer deaths (only non-cancer causes)
  # new: All new coded cancer and non-cancer deaths
  # all: Everything, including repeats of the same patient, and patients with no causes of death
  # cara: New congenital anomaly deaths, cf. https://ncr.plan.io/issues/15123
  # cara_all: All congenital anomaly deaths
  class CancerDeathCommon < DeathFile # rubocop:disable Metrics/ClassLength
    CARA_PATTERN = /\A(D215\z|D821|D1810|E7030|P350|P351|P371|P358|P832|K070|
          Q(?!038\z|039\z|0461\z|0780\z|0782\z|101\z|102\z|103\z|105\z|135\z|170\z|171\z|172\z|
              173\z|174\z|
              175\z|179\z|180\z|181\z|182\z|184\z|185\z|186\z|187\z|1880\z|189\z|2111\z|250\z|
              2541\z|
              261\z|270\z|314.*\z|315\z|320\z|322.*\z|3300\z|331.*\z|336\z|357\z|381\z|382\z|3850\z|
              400\z|401\z|4021\z|430.*\z|4320\z|4381\z|4382\z|444\z|4583\z|501.*\z|502\z|505\z|
              52.*\z|53.*\z|544\z|5520\z|5521\z|610\z|627.*\z|633\z|653\z|654\z|655\z|
              656.*\z|658.*\z|659.*\z|661\z|662\z|663\z|664\z|665\z|666\z|667\z|668.*\z|669\z|
              670\z|671\z|672\z|673\z|674.*\z|675.*\z|678\z|680\z|6810\z|6821\z|683\z|684\z|
              685\z|7400\z|752\z|753.*\z|760\z|7643\z|765\z|7660\z|7662\z|7671\z|825.*\z|8280\z|
              8281\z|833\z|845\z|846\z|8911\z|899\z|95.*\z).*)\z
    /x
    # Rare disease pattern, plan.io task #14947, details in #match_rare_disease_row?
    # Extract used until 2020-10
    # RD_PATTERN = /\A(D761|D762|D763|E830|M313|M317|M301|M314|I776|I778|M352|M315|M316|M321|
    #   M330|M332|M331|M339|M340|M341|M348|M349|M083|M084|M082|M080|M300|M308|J991|N085|N164|
    #   M328|M329|M609|G724|M608|M089|G903)\z
    # /x
    # Updated criteria implemented 2021-10, cf. plan.io #14947#note-18
    # RD_PATTERN = /\A(E009|E030|E031|E700|E701|M313|M317|M301|M314|I776|I778|M352|M315|M316|
    #   M321|M330|M332|M331|M339|M340|M341|M348|M349|M083|M084|M082|M080|M300|M308|J991|N085|
    #   N164|M328|M329|M609|G724|M608|M089|M360)\z
    # /x
    # Updated criteria implemented 2021-11, cf. plan.io #14947#note-21
    # RD_PATTERN = /\A(D761|D762|D763|U10.*|M303|E752)\z
    # /x
    # Custom criteria used 2024-10, cf. JIRA NDRS3-337
    # RD_PATTERN = /\A(Q81.*)\z/
    # Updated criteria implemented 2022-09, cf. plan.io #30091 and #14947
    RD_PATTERN = /\A(E009|E030|E031|G724|I776|I778|J991|M080|M082|M083|M084|M089|M300|M301|M303|
      M308|M313|M314|M315|M316|M317|M321|M328|M329|M330|M331|M332|M339|M340|M341|M348|M349|M352|
      M360|M608|M609|N085|N164|I777|E700|E701|E752|E830|E880|G903|G232|G233|Q850)\z
    /x
    # Extract used until 2020-11
    # RD_PATTERN_POST_2015 = /\A(Q.*)\z/
    # Updated criteria implemented 2021-11, cf. plan.io #14947#note-21
    # RD_PATTERN_POST_2015 = /\AZZZZZZ\z/ # match no ICD codes
    # Custom criteria used 2024-10, cf. JIRA NDRS3-337
    # RD_PATTERN_POST_2015 = /\A(Q81.*)\z/
    # Updated criteria implemented 2022-09, cf. plan.io #30091 and #14947
    RD_PATTERN_POST_2015 = /\A(Q.*)\z/
    # Extract used until 2020-10
    # RD_STRING_PATTERNS = [[/LSTR/, /SYND/],
    #                       [/MENK/],
    #                       [/WOLFRAM/],
    #                       [/DIDMOAD/],
    #                       [/MULTI/, /ATROPHY/]].freeze
    # Custom criteria used 2024-10, cf. JIRA NDRS3-337
    # RD_STRING_PATTERNS = [[/EPIDERMOLYSIS BULLOSA/],
    #                       [/EPIDERMOLYSIS/]].freeze
    # Updated criteria implemented 202x1-10, cf. plan.io #14947#note-18
    RD_STRING_PATTERNS = [].freeze
    # C / D00-D48, confirmed as sufficient against early 2017 cancer death files
    SURVEILLANCE_CODES = { 'cd' => /^(C|D[0123]|D4[0-8])/, # New cancer deaths (only cancer causes)
                           'new' => /^[A-Z]/, # New coded cancer and non-cancer deaths
                           'ncd' => /^[A-Z]/, # New coded non-cancer deaths (non-cancer causes)
                           'cara' => CARA_PATTERN, # New congenital anomalies
                           'cara_all' => CARA_PATTERN, # All congenital anomalies, including repeats
                           'rd' => RD_PATTERN, # New rare diseases
                           'rd_all' => RD_PATTERN, # All rare diseases, including repeats
                           'all' => // }.freeze # Everything, including repeats of the same patient

    # Map column names from encore cancer deaths mapping to MBIS fields
    FIELD_MAP = {
      'generic_registrycode' => nil, 'surname' => 'snamd', 'previoussurname' => 'namemaid',
      'forenames' => 'creg_fnamd', 'aliases' => 'creg_aliasd_all',
      'sex' => 'creg_sex', 'placeofbirth' => 'pobt',
      'dateofbirth' => 'dob', 'dateofbirth_text' => nil,
      'address' => 'addrdt', 'postcode' => 'pcdr',
      'occupation' => 'occdt', # 'occupation_husband_father' => 'occhft',
      'occupation_mother' => 'occmt', 'dateofdeath' => 'dod', 'dateofdeath_text' => nil,
      'placeofdeath' => 'podt', 'ons_text1a' => 'codt_codfft_1_255',
      'ons_text1b' => 'codt_codfft_2_255',
      'ons_text1c' => 'codt_codfft_3_codt_6_255', # Combine CODT_3 and CODT_6 (cause 1c + 1d)
      'ons_text2' => 'codt_codfft_4_255',
      'ons_text' => 'codt_codfft_5_255extra',
      'ons_code1a' => 'matched_cause_code_1', 'ons_code1b' => 'matched_cause_code_2',
      'ons_code1c' => 'matched_cause_code_3', 'ons_code2' => 'matched_cause_code_4',
      'ons_code' => 'ons_code',
      'deathcausecode_underlying' => 'icdu_icduf',
      'deathcausecode_significant' => 'icdsc_icdscf',
      'registration_details' => 'dor', # Old registration details not in MBIS
      'certifier' => 'certifer', 'coronerscertificate' => 'corcertt', 'coronersname' => 'namec',
      'coronersarea' => 'corareat', 'dateofinquest' => 'doinqt', 'informantqualification' => nil,
      'informantqualification_text' => nil,
      'inquestcertificatetype' => 'inqcert', 'inquestcertificatetype_text' => nil,
      'nhsnumber' => 'nhsnumber',
      'ageu1d' => 'ageu1d' # Needed for CARA, plan.io #15123
    }.freeze

    # List of MBIS death fields needed (for NHSD migration)
    RAW_FIELDS_USED = (%w[
      snamd
      namemaid
      fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2
      aliasd_1 aliasd_2
      sex
      pobt
      dobyr dobmt dobdy
      addrdt
      pcdr
      occdt
      occmt
      dodyr dodmt doddy
      podt
    ] + (1..5).collect { |i| "codt_#{i}" } +
                  (1..65).collect { |i| "codfft_#{i}" } +
                  (1..20).collect { |i| "cod10rf_#{i}" } +
                  (1..20).collect { |i| "cod10r_#{i}" } +
                  (1..20).collect { |i| "lineno9f_#{i}" } +
                  (1..20).collect { |i| "lineno9_#{i}" } +
                  (1..20).collect { |i| "icdf_#{i}" } +
                  (1..20).collect { |i| "icdpvf_#{i}" } +
                  (1..20).collect { |i| "icd_#{i}" } +
                  (1..20).collect { |i| "icdpv_#{i}" } +
                  %w[
      icduf icdu
      icdscf icdsc
      dor
      certifer
      corcertt
      namec
      corareat
      doinqt
      inqcert
                  ] + (1..5).collect { |i| "nhsno_#{i}" } +
                  %w[ageu1d]).freeze

    def initialize(filename, e_type, ppats, filter = 'cd', ppatid_rowids: nil)
      super
      raise "Unknown pattern #{filter.inspect}" unless SURVEILLANCE_CODES.key?(filter)

      @col_pattern = table_mapping.collect do |col|
        [col['column'] || col['standard_mapping'],
         col['unpack_pattern'].tr('a', 'A')] # Space separate, not null separate
      end
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w(icduf)
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w(icdu)
      @icd_fields_all = @icd_fields_f + @icd_fields
    end

    private

    # Load the required mapping file based on @batch.e_type
    def table_mapping
      mapping_file = 'cd_mapping.yml'
      YAML.load_file(SafePath.new('mappings_config').join(mapping_file))['cd']
    end

    # Does this row match the current extract
    # Records selected will have a C / D00-D48 code.
    # Records must also have an NHS number. (Encore has received very occasional annual
    # custom death refreshes of whole years of patients without NHS numbers)
    #
    # We should probably tweak this, to re-extract rows with substantial changes. However, as
    # the MBIS data is already only full coded records, substantial changes should be very rare.
    def match_row?(ppat, _surveillance_code = nil)
      return true if @filter == 'all' # Return everything, not just new ones, even without NHS nos.

      if %w[rd rd_all].include?(@filter)
        return false unless match_rare_disease_row?(ppat)
      else
        return false unless match_icd_pattern?(ppat)
      end
      if %w[cara cara_all].include?(@filter) &&
         (!%w[921 926 969].include?(ppat.death_data['ctrypob']) ||
          extract_field(ppat, 'por_in_england').zero?) &&
         !extract_field(ppat, 'patientid')
        # For CARA, exclude death matches for patients not born in England or not resident
        # in England. CARA don't want patients resident overseas who died in England.
        # Country codes: 921 = ENGLAND, 926 = UNITED KINGDOM NOT OTHERWISE SPECIFIED
        # 969 seems to be a weird catch-all code not on the official list
        #     - presumably a generic "unknown"
        # https://www.ons.gov.uk/methodology/classificationsandstandards/otherclassifications/nationalstatisticscountryclassification
        return false
      end
      if %w[rd rd_all].include?(@filter) &&
         (ppat.death_data['gorr'] == 'W' || ppat.death_data['gor9r'] == 'W99999999') &&
         !extract_field(ppat, 'patientid')
        # For RD, exclude death matches for patients in Wales, except when extracting
        # matching death details for known patients.
        return false
      end

      # return false if ppat.death_data['gorr'] == 'W' # Exclude patients in Wales for comparisons
      # (excludes some patients actually in England...)
      # return false unless ppat.death_data.ccg9pod.to_s.start_with?('E')
      ppat.unlock_demographics('', '', '', :export)
      if %w[cara cara_all].include?(@filter)
        # CARA wants only people born in / after 2016
        return false unless death_field(ppat, 'dobyr').to_i >= 2016
      end
      return false if ExcludedMbisid.excluded_mbisid?(extract_field(ppat, 'mbisid'))
      ppat.demographics['nhsnumber'].present?
    end

    def match_icd_pattern?(ppat)
      pattern = SURVEILLANCE_CODES[@filter]
      @icd_fields_all.any? { |field| pattern.match?(ppat.death_data[field]) }
    end

    # Rare disease inclusion criteria
    # Rare disease extracts must match any ICD codes from RD_PATTERN, or any ICD codes in
    # RD_PATTERN_POST_2015 for deaths from 2015-01-01 onwards, or any word fragments in
    # any of the RD_STRING_PATTERNS arrays of CODT free-text regular expressions
    def match_rare_disease_row?(ppat)
      return true if match_icd_pattern?(ppat)
      if ppat.death_data.dodyr.to_i >= 2015 &&
         @icd_fields_all.any? { |field| RD_PATTERN_POST_2015.match?(ppat.death_data[field]) }
        return true
      end

      # Match words within each of the CODT fields, or across all CODFFT
      all_codt = if ppat.death_data.read_attribute('codfft_1').blank?
                   (1..5).collect { |i| ppat.death_data.read_attribute("codt_#{i}").upcase }.compact
                 else
                   [(1..65).collect { |i| ppat.death_data.read_attribute("codfft_#{i}").upcase }.
                     compact.join("\n")]
                 end
      all_codt.any? do |codt|
        RD_STRING_PATTERNS.any? { |regexs| regexs.all? { |re| re.match?(codt) } }
      end
    end

    # Secondary filter, to allow separate cancer death / non-cancer death files
    # This acts as an output filter, rather than a selection filter, to ensure that only a
    # single death card is extracted, if the cause of death changes from cancer to non-cancer.
    # (If the cause changes from non-cancer to cancer, this will be matched as a cancer death.)
    def exclude_cancer_death?(ppat)
      return false unless @filter == 'ncd'
      pattern = SURVEILLANCE_CODES['cd']
      @icd_fields_all.any? { |field| ppat.death_data[field] =~ pattern }
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      return if exclude_cancer_death?(ppat)
      return if !/(^|_)all\z/.match?(@filter) && already_extracted?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      @fields.collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refactor with DelimitedFile, CancerMortalityFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'creg_fnamd' # First 3 forenames, space separated
        return %w[fnamd1 fnamd2 fnamd3].collect { |f| super(ppat, f) }.compact.join(' ')
      when 'creg_aliasd_all' # Concatenate all aliases
        return [super(ppat, 'aliasd_1'), super(ppat, 'aliasd_2')].compact.join(' ')
      when 'creg_sex'
        val = super(ppat, 'sex')
        return { '1' => 'M', '2' => 'F', '3' => 'I' }[val]
      end
      val = super(ppat, field)
      case field
      when 'addrdt', 'podt'
        # Remove leading spaces from addresses in LEDR extracts
        val = val&.sub(/\A +/, '')
      when 'namec' # Blank if inquest type not = 1, 2 or 9
        val = '' unless [1, 2, 9].include?(death_field(ppat, 'inqcert'))
      when 'inqcert'
        val = '' if val == 0 # Make LEDR extract more like M204: LEDR sends explicit 0's here
      when 'agec' # Remove leading zeros
        # TODO: Refactor with CancerMortalityFile, DeathFileSimple, into DeathFile
        val = val.to_i.to_s if val.present?
      end
      val
    end
  end
end
