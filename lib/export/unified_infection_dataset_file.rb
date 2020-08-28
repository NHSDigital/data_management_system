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
