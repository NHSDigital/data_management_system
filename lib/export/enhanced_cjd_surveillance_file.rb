module Export
  # Enhanced surveillance of individuals identified as at increased risk of vCJD/CJD in the UK
  # due to iatrogenic exposures or other indicators of increased risk
  # Specification: plan.io #24922
  # All-cause death registrations
  class EnhancedCjdSurveillanceFile < DeathFileSimple
    # pr = Project.find(227)
    # pr.project_nodes.sort_by(&:id).collect { |data_item| data_item.name }
    FIELDS = (
      %w[patientid doddy dodmt dodyr pcdpod podt ctydpod occdt occtype pcdr] +
      ['codfft', # Requested as MED_C_OF_D_FREE_FORMAT: Up to 65 lines of cause of death ..
       'codt', # Requested as MED_C_OF_D_LINE: Cause of death Text ...
       'icdf', # requested as F_COD_CODE: ICD9 final code pre 2000, ...
       'icd', # Requested as S_COD_CODE: ICD9 code pre 2000, ...
       'occfft'] # Requested as DEC_OCCUPATION_FREE: Occupation of deceased free format text
    ).freeze

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end
  end
end
