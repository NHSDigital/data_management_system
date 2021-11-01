module Export
  # Export and de-pseudonymise monthly / annual KIT death PID extract
  # Specification: plan.io #25535 / MBIS project 276
  class KitDeathsPid < DeathFileSimple
    # pr = Project.find(276)
    # pr.project_nodes.sort_by(&:id).collect { |data_item| data_item.name }
    FIELDS = (
      %w[mbisid nhsnorss fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2 namemaid snamd] +
      %w[nhsno] + # Requested as DEC_CONF_NHS_NUMBER: NHSNO from NHSCR (or other sources ...)
      %w[fnamdx]
    ).freeze

    # Returns an array of filename format pattern, for output (e.g. csv or txt file),
    # summary file and zip file [fname, fname_summary, fname_zip]
    # filter is the extract type filter
    # period is :weekly or :monthly or :annual
    def self.fname_patterns(_filter, period)
      case period
      when :weekly
        %w[WEEK%Y%m%dD_MBIS.TXT WEEK%Y%m%dP_MBIS.TXT %Y%m%d_MBIS.zip]
      when :monthly
        %w[MTH%Y-%mD_MBIS.TXT MTH%Y-%mP_MBIS.TXT MTH%Y-%m_MBIS.zip]
      when :annual
        %w[YEAR%YD.TXT YEAR%YP_MBIS.TXT YEAR%Y_MBIS.zip]
      else raise "Unknown period #{period}"
      end
    end

    private

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: true }
    end

    def fields
      FIELDS.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end.uniq
    end
  end
end
