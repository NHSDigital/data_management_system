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
  class CancerDeathCommon < DeathFile
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
    # Rare disease pattern, plan.io task #14947
    RD_PATTERN = /\A(D180|D55.*|D56[^3]?|D57[^3]?|D58.*|D610|D640|D66.*|
        D67.*|D680|D681|D682|D691|D692|D70.*|D71.*|D720|D740|D750|D761|
        D8(?!21\z|93\z).*\z|
        E7[^3].*|E80[^4]?|E83.*|E84.*|E85.*|E88.*|G12.*|G318|G60.*|G70.*|
        G71.*|G90.*|I34.*|I420|I421|I422|I423|I424|I425|I45[^9]?|K741|
        K743|K746|M301|M313|M317|Q103|Q105|Q544|Q684|Q833|Q845|Q846)\z
    /x.freeze
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
      'ons_text1c' => 'codt_codfft_3_255', 'ons_text2' => 'codt_codfft_4_255',
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

    def initialize(filename, e_type, ppats, filter = 'cd', ppatid_rowids: nil)
      super
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

      pattern = SURVEILLANCE_CODES[@filter]
      return false if @icd_fields_all.none? { |field| ppat.death_data[field] =~ pattern }
      if %w[cara cara_all rd rd_all].include?(@filter) &&
         (ppat.death_data['gorr'] == 'W' || ppat.death_data['gor9r'] == 'W99999999') &&
         !extract_field(ppat, 'patientid')
        # For CARA / RD, exclude death matches for patients in Wales, except when extracting
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
      ppat.demographics['nhsnumber'].present?
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
      when 'space1'
        return ' '
      when 'creg_fnamd' # First 3 forenames, space separated at 20 character intervals
        # (The specification says delimiter present at position 21, but this isn't reflected in
        #  the historical cancer deaths files received)
        # return %w(fnamd1 fnamd2 fnamd3).collect { |f| [super(ppat, f)].pack('A20') }.join(' ')
        return %w(fnamd1 fnamd2 fnamd3).collect { |f| [super(ppat, f)].pack('A19') }.join(' ').
               rstrip
      when 'creg_aliasd_all' # Concatenate all aliases
        return [super(ppat, 'aliasd_1'), super(ppat, 'aliasd_2')].compact.join(' ')
      when 'creg_sex'
        val = super(ppat, 'sex')
        return { '1' => 'M', '2' => 'F', '3' => 'I' }[val]
      end
      val = super(ppat, field)
      case field
      when 'addrdt', 'podt' # Commas replaced with slashes in weekly cancer deaths extract
        val = val.to_s.tr(',', '/')
        # Remove leading spaces from addresses in LEDR extracts
        val = val.sub(/\A +/, '')
      when 'namec' # Blank if inquest type not = 1, 2 or 9
        val = '' unless [1, 2, 9].include?(death_field(ppat, 'inqcert'))
      when 'snamd'
        val = "#{val}/"
      when 'inqcert'
        val = '' if val == 0 # Make LEDR extract more like M204: LEDR sends explicit 0's here
      when 'pcdr' # Remove spaces from 7 character postcodes, have 2 spaces in e.g. "A1  1AA"
        val = val&.postcodeize(:db)
      end
      val
    end
  end
end
