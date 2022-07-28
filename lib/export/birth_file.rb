module Export
  # Base class for exporting mapped MBIS birth data files
  class BirthFile < BaseFile
    # Export data to file, returns number of records emitted
    def export
      i = 0
      CSV.open(@filename, "wb#{csv_encoding && ':' + csv_encoding}", **csv_options) do |csv|
        header_rows.each { |row| csv << row }
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        @ppats.includes(:birth_data, :ppatient_rawdata).send(meth) do |ppat|
          row = extract_row(ppat, i + 1)
          if row
            csv << row
            i += 1
          end
        end
        # Print footer rows
        footer_rows(i).each { |row| csv << row }
      end
      i
    end

    private

    def birth_field(ppat, field)
      # Prefer data from demographics to BirthData, in case identifiable fields
      # are in demographics, but accidentally also listed in BirthData table.
      if ppat.demographics.key?(field)
        ppat.demographics[field]
      elsif ppat.has_attribute?(field)
        ppat[field]
      elsif ppat.birth_data.has_attribute?(field)
        ppat.birth_data[field]
      end # else nil implicit
    end

    # Emit the value for a particular field, including common field mappings
    # (May be extended by subclasses for extract-specific tweaks)
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'dob_iso', 'dobm_iso'
        val = birth_field(ppat, field.split('_').first)
        # Rewrite DOB from YYYYMMDD to YYYY-MM-DD (for M204 and LEDR)
        # Rewrite DOBM from DD/MM/YYYY to YYYY-MM-DD (for M204) / from YYYYMMDD (for LEDR)
        if val =~ /\A[0-9]{8}\z/ # Convert YYYYMMDD to YYYY-MM-DD
          val = "#{val[0..3]}-#{val[4..5]}-#{val[6..7]}"
        elsif val =~ %r(\A([0-9][0-9]|- )/([0-9][0-9]|- )/([0-9]{4}|-)\z)
          # Convert DD/MM/YYYY to YYYY-MM-DD
          # Inexact dates may be of form "- /MM/YYYY" or "- /- /YYYY" or "DD/MM/-"
          # Rewrite "- " components with 0000
          val = "00#{val[2..-1]}" if val =~ %r{\A- /([0-9][0-9]|- )/([0-9]{4}|-)\z}
          val = "#{val[0..2]}00#{val[5..-1]}" if val =~ %r{\A[0-9][0-9]/- /([0-9]{4}|-)\z}
          val = "#{val[0..5]}0000" if val =~ %r{\A[0-9][0-9]/[0-9][0-9]/-\z}
          val = "#{val[6..9]}-#{val[3..4]}-#{val[0..1]}"
        end
        return val
      when 'dob_yyyyq'
        dob = birth_field(ppat, 'dob')
        return "#{dob[0..3]}#{(dob[4..5].to_i + 2) / 3}"
      when 'por_in_england' # 1 if the place of residence is in England, 0 otherwise or if unknown
        por_in_england = %w[A B C D E F G H J K].include?(ppat.birth_data['gorrm']) ||
                         ppat.birth_data['lsoarm']&.starts_with?('E')
        return por_in_england ? 1 : 0
      when 'sex_statistical' # If SEX=3 (indeterminate), set to 1.
        val = birth_field(ppat, 'sex')
        return val == '3' ? '1' : val
      when 'mbisid'
        return birth_field(ppat, 'ledrid') || birth_field(ppat, 'mbism204id')
      when 'patientid' # Linkage identifier for extracting matched patient records
        return @ppatid_rowids[ppat.id]
      end
      val = birth_field(ppat, field)
      val
    end
  end
end
