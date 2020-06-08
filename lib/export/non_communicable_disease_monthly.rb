module Export
  # Export and de-pseudonymise monthly non-communicable diseases death data
  # Specification in plan.io #10954
  # Use filter='all' to extract all of a batch, instead of comparing against past extracts
  class NonCommunicableDiseaseMonthly < DeathFile
    def initialize(filename, e_type, ppats, filter = 'ncd')
      super
      @fields = %w[ctydpod ctypod doddy dodmt dodyr sex_statistical agec agecunit dor
                   ccgr ctryr ctydr ctyr wardr ccg9r ward9r mbisid icdu icduf]
    end

    private

    def header_rows
      [@fields.collect(&:upcase)]
    end

    def csv_encoding
      'windows-1252:utf-8'
    end

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: false }
    end

    # Does this row match the current extract
    def match_row?(_ppat, _surveillance_code = nil)
      true # Return everything
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      return if @filter != 'all' && already_extracted?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      @fields.collect { |field| extract_field(ppat, field) }
    end
  end
end
