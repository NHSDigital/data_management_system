module Export
  # Export and de-pseudonymise weekly cancer death data
  # Specification file: "Cancer Deaths Specification 03-15 2008.docx"
  # Old-format fixed width file
  class CancerDeathFixedWeekly < CancerDeathCommon
    def initialize(filename, e_type, ppats, filter = 'cd')
      super
      # Historic file has 49 (England) or 12 (Wales) blank spaces at the end of each row
      # Wales data starts with the surname, without 2 digits for the registry code at the start.
      @col_pattern << %w(space1 A49)
      @fields = @col_pattern.collect(&:first).collect { |col| FIELD_MAP[col] || col }
      @pattern = @col_pattern.collect(&:last).join
    end

    # Export data to file, returns number of records emitted
    # Produces a fixed-width file, not a CSV file
    def export
      i = 0
      File.open(@filename, 'wb') do |outf|
        header_rows.each { |row| outf << row }
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        @ppats.includes(:death_data, :ppatient_rawdata).send(meth) do |ppat|
          row = extract_row(ppat, i + 1)
          if row
            # Use Windows-1252 encoding for fixed width cancer death export
            packed_row = row.collect { |s| s.to_s.encode('windows-1252') }.pack(@pattern)
            outf << packed_row + "\r\n"
            i += 1
          end
        end
        # Print footer rows
        footer_rows(i).each { |row| outf << row }
      end
      i
    end
  end
end
