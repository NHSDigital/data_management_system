module Export
  # Export and de-pseudonymise Unified Infection Dataset extract
  # Specification: https://ncr.plan.io/issues/23192
  # "Unified Infection Dataset" plan.io #23192
  # All-cause death registrations
  class UnifiedInfectionDatasetFile < DeathFileSimple
    # TODO: Refactor with EnhancedSurveillanceVaccinePreventableDeathsFile

    FIELDS = (
      %w[patientid] +
      %w[ccg9pod] +
      ['nhsno', # Requested as DEC_CONF_NHS_NUMBER: NHSNO from NHSCR (or other sources ...)
       'icd', # Requested as S_COD_CODE: ICD9 code pre 2000, ...
       'icdf', # requested as F_COD_CODE: ICD9 final code pre 2000, ...
       'icdpv', # Requested as ICD10PV: ICD9PV code pre 2000, ...
       'icdpvf'] + # Requested as ICD10PVF: Final ICD9PV code pre 2000, ...
      %w[nhsnorss namemaid aliasd fnamdx addrdt snamd fnamd1 fnamd2 fnamd3
         icdu icduf icdsc icdscf nhsind esttyped podt pcdpod cestrssr cestrss
         sex_statistical pcdr dobyr dobmt dobdy dodyr dodmt doddy postmort] +
      ['lineno9', # Requested as S_COD_LINE: Line number of cause text line for ICD10 ...
       'lineno9f', # Requested as F_COD_LINE: Final line number of cause text line for ...
       'codfft', # Requested as MED_C_OF_D_FREE_FORMAT: Up to 65 lines of cause of death ...
       'cod10r', # Requested as S_COD_LINE: Cause of death row position
       'cod10rf'] + # Requested as F_COD_LINE: Final cause of death row position
      %w[mbisid dor ccg9r ctrypob agec agecunit ctyr ceststay ctryr]).freeze
    # ?? Specification included 'dob: Date of birth of child' which isn't actually death field

    SPECIAL = {
      # Auto-generated using:
      # $ cat config/mappings/deaths_mapping.yml |grep -e 'field:'|cut -d: -f2-|tr -d " " | \
      #   egrep '_'| sed -e 's/_[0-9][0-9]*$//'|uniq -c|sed -Ee 's/ *([0-9]+) (.*)/      \2:'\
      #   '-> { (1..\1).collect { |i| "\2_#{i}" } },/'
      cod10r: -> { (1..20).collect { |i| "cod10r_#{i}" } },
      cod10rf: -> { (1..20).collect { |i| "cod10rf_#{i}" } },
      codt: -> { (1..5).collect { |i| "codt_#{i}" } },
      icd: -> { (1..20).collect { |i| "icd_#{i}" } },
      icdf: -> { (1..20).collect { |i| "icdf_#{i}" } },
      icdpv: -> { (1..20).collect { |i| "icdpv_#{i}" } },
      icdpvf: -> { (1..20).collect { |i| "icdpvf_#{i}" } },
      lineno9: -> { (1..20).collect { |i| "lineno9_#{i}" } },
      lineno9f: -> { (1..20).collect { |i| "lineno9f_#{i}" } },
      aksnamd: -> { (1..5).collect { |i| "aksnamd_#{i}" } },
      akfnamd_1: -> { (1..5).collect { |i| "akfnamd_1_#{i}" } },
      akfnamd_2: -> { (1..5).collect { |i| "akfnamd_2_#{i}" } },
      akfnamd_3: -> { (1..5).collect { |i| "akfnamd_3_#{i}" } },
      akfndi: -> { (1..5).collect { |i| "akfndi_#{i}" } },
      aliasd: -> { (1..2).collect { |i| "aliasd_#{i}" } },
      fnamdx: -> { (1..2).collect { |i| "fnamdx_#{i}" } },
      nhsno: -> { (1..5).collect { |i| "nhsno_#{i}" } },
      occfft: -> { (1..4).collect { |i| "occfft_#{i}" } },
      codfft: -> { (1..65).collect { |i| "codfft_#{i}" } }
    }.freeze

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end

    # Return only new rows, and ignore rows without NHS numbers
    def match_row?(ppat, _surveillance_code = nil)
      # ??? For a full extract (instead of patient matching), maybe return only deaths in England?
      # i.e. return false unless extract_field(ppat, 'pod_in_england') == 1 // super

      ppat.unlock_demographics('', '', '', :export)
      ppat.demographics['nhsnumber'].present? && !already_extracted?(ppat)
    end
  end
end
