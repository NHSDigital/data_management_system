module Export
  # UID Weekly data extract
  # Specification: plan.io #27458
  # All-cause death registrations
  class UidWeekly < DeathFileSimple
    # pr = Project.find(2545)
    # pr.project_nodes.sort_by(&:id).collect { |data_item| data_item.name }
    FIELDS = (
      ['nhsno', # Requested as DEC_CONF_NHS_NUMBER: NHSNO from NHSCR (or other sources ...)
       'icd', # Requested as S_COD_CODE: ICD9 code pre 2000, ...
       'icdf', # requested as F_COD_CODE: ICD9 final code pre 2000, ...
       'icdpv', # Requested as ICD10PV: ICD9PV code pre 2000, ...
       'icdpvf'] + # Requested as ICD10PVF: Final ICD9PV code pre 2000, ...
      %w[nhsnorss namemaid fnamdx snamd fnamd1 fnamd2 fnamd3
         icdu icduf icdsc icdscf
         sex_statistical dobyr dobmt dobdy dodyr dodmt doddy] +
      ['lineno9', # Requested as S_COD_LINE: Line number of cause text line for ICD10 ...
       'lineno9f'] + # Requested as F_COD_LINE: Final line number of cause text line for ...
      %w[mbisid]).freeze

    # Returns an array of filename format pattern, for output (e.g. csv or txt file),
    # summary file and zip file [fname, fname_summary, fname_zip]
    # filter is the extract type filter
    # period is :weekly or :monthly or :annual
    def self.fname_patterns(_filter, period)
      prefix = 'UID_'
      suffixes = case period
                 when :weekly
                   %w[%Y%m%d_MBIS.csv %Y%m%d_summary.txt %Y%m%d_MBIS.zip]
                 when :monthly
                   %w[%Y-%m_MBIS.csv %Y-%m_summary.txt %Y-%m_MBIS.zip]
                 when :annual
                   %w[%Y_MBIS.csv %Y_summary.txt %Y_MBIS.zip]
                 else raise "Unknown period #{period}"
                 end
      suffixes.collect { |s| prefix + s }
    end

    private

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end
  end
end
