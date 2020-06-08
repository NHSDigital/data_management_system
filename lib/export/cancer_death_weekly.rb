module Export
  # Export and de-pseudonymise weekly cancer death data
  # Specification file: "Cancer Deaths Specification 03-15 2008.docx"
  class CancerDeathWeekly < CancerDeathCommon
    def initialize(filename, e_type, ppats, filter = 'cd', ppatid_rowids: nil)
      super
      # Exclude fields not in MBIS
      @fields = @col_pattern.collect(&:first).collect { |col| FIELD_MAP[col] }.compact
    end

    def header_rows
      [@col_pattern.collect(&:first).select { |col| FIELD_MAP[col] }.collect(&:upcase)]
    end
  end
end
