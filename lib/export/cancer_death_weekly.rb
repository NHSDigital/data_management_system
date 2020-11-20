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

    # Returns an array of filename format pattern, for output (e.g. csv or txt file),
    # summary file and zip file [fname, fname_summary, fname_zip]
    # filter is the extract type filter
    # period is :weekly or :monthly or :annual
    def self.fname_patterns(filter, period)
      prefix = filter.sub(/_[^_]*$/, '').upcase
      suffixes = case period
                 when :weekly
                   %w[%Y%m%d.csv %Y%m%d_summary.txt %Y%m%d_MBIS.zip]
                 when :monthly
                   %w[%Y-%m.csv %Y-%m_summary.txt %Y-%m_MBIS.zip]
                 when :annual
                   %w[%Y.csv %Y_summary.txt %Y_MBIS.zip]
                 else raise "Unknown period #{period}"
                 end
      suffixes.collect { |s| prefix + s }
    end
  end
end
