module Export
  # Mixin for simple birth / death files
  # (CSV data with a header row, no special fields)
  # Use filter='all' to get all records from a batch (including repeats)
  # or filter='new' to get only new records in a batch (excluding records sent before)
  # or filter='all_nhs' for all records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new records with NHS numbers (excluding such records sent before)
  module SimpleCsv
    def initialize(filename, e_type, ppats, filter = nil, ppatid_rowids: nil)
      super
      @fields = fields
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

    # Return all rows, or only rows with NHS numbers
    def match_row?(ppat, _surveillance_code = nil)
      return true unless @filter == 'all_nhs' || @filter == 'new_nhs'

      ppat.unlock_demographics('', '', '', :export)
      ppat.demographics['nhsnumber'].present?
    end

    def fields
      raise 'Override this method in a subclass'
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      return if @filter != 'all' && already_extracted?(ppat)

      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      @fields.collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      val = super(ppat, field)
      val = nil if val == '' # Remove unnecessary double quoted fields in output
      val
    end
  end
end
