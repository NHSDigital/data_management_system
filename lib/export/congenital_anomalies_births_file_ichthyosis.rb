module Export
  # Export and de-pseudonymise congenital anomalies (CARA) births extract
  # Specification in plan.io #24291
  class CongenitalAnomaliesBirthsFileIchthyosis < CongenitalAnomaliesBirthsFile
    SURVEILLANCE_PATTERN = /
       \A(Q802|Q804|Q808|Q809)\z
    /x

    # List of MBIS birth fields needed (for NHSD migration)
    RAW_FIELDS_USED = (Export::CongenitalAnomaliesBirthsFileIchthyosis::RAW_FIELDS_USED +
                       %w[gorrm lsoarm]
                      ).freeze

    def initialize(filename, e_type, ppats, filter, ppatid_rowids: nil)
      super(filename, e_type, ppats, filter, ppatid_rowids: ppatid_rowids)
      # Fields to check for matches
      @icd_fields_f = (1..20).collect { |i| "icdpvf_#{i}" }
      @icd_fields = (1..20).collect { |i| "icdpv_#{i}" }
      @pattern = SURVEILLANCE_PATTERN
    end

    private

    def match_row?(ppat, _surveillance_code = nil)
      # TODO: Refactor with match_row? in BirthFileSimple and CongenitalAnomaliesDeathFile
      if @pattern
        ppat.unlock_demographics('', '', '', :export) # For births, ICD fields are disclosive
        icd_fields = @icd_fields_f
        # Check only final codes, if any present, otherwise provisional codes
        icd_fields = @icd_fields if icd_fields.none? { |f| extract_field(ppat, f).present? }
        return false if icd_fields.none? { |f| extract_field(ppat, f) =~ @pattern }
      end
      # CARA excludes patients not resident in England
      return false if extract_field(ppat, 'por_in_england').zero?

      super
    end
  end
end
