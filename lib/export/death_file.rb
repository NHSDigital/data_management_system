module Export
  # Base class for exporting mapped MBIS death data files
  class DeathFile < BaseFile
    # Export data to file, returns number of records emitted
    def export
      i = 0
      CSV.open(@filename, "wb#{csv_encoding && ':' + csv_encoding}", csv_options) do |csv|
        header_rows.each { |row| csv << row }
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        keyword_args = @ppats.respond_to?(:find_each) ? { batch_size: 10_000 } : {}
        @ppats.includes(:death_data, :ppatient_rawdata).send(meth, **keyword_args) do |ppat|
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

    def death_field(ppat, field)
      # Prefer data from demographics to DeathData, in case identifiable fields
      # are in demographics, but accidentally also listed in DeathData table.
      if ppat.demographics.key?(field)
        ppat.demographics[field]
      elsif ppat.has_attribute?(field)
        ppat[field]
      elsif ppat.death_data.has_attribute?(field)
        ppat.death_data[field]
      end # else nil implicit
    end

    # Emit the value for a particular field, including common field mappings
    # (May be extended by subclasses for extract-specific tweaks)
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'cod10r', 'cod10rf', 'codt', 'icd', 'icdf', 'icdpv', 'icdpvf', # non-identifying
           'lineno9', 'lineno9f', 'occfft', 'codfft', 'aksnamd', 'akfnamd1', # non-identifying
           'akfnamd2', 'akfnamd3', 'akfnd4i', 'aliasd', 'fnamdx', 'nhsno' # direct identifiers
        # Fields which occur multiple times, e.g. cod10r_1 ... cod10r_20, where the singular
        # version does not exist.
        raise "Invalid field #{field}"
      when 'dob'
        return %w[dobyr dobmt dobdy].collect { |field2| death_field(ppat, field2) }.join
      when 'dod'
        return %w[dodyr dodmt doddy].collect { |field2| death_field(ppat, field2) }.join
      when 'dob_ddmmyy'
        return %w[dobdy dobmt dobyr].collect { |field2| death_field(ppat, field2) }.join
      when 'dod_ddmmyy'
        return %w[doddy dodmt dodyr].collect { |field2| death_field(ppat, field2) }.join
      when 'dob_iso'
        return %w[dobyr dobmt dobdy].collect { |field2| death_field(ppat, field2) }.join('-')
      when 'doryr'
        return death_field(ppat, 'dor').to_s[0..3] # Just the year of DOR
      when /matched_cause_code_([0-9]+)$/
        # Death cause codes (comma separated) that match the corresponding line from the text
        # lineno values are always 1-6
        i = Regexp.last_match[1].to_i
        # ONS quirks mode: only extract causes 1(a), 1(b), 1(c), 2 with corresponding text
        # (or if codfft is defined, i.e. there may be free text blank lines)
        return if [1, 2, 3, 4].include?(i) &&
                  death_field(ppat, 'codfft_1').blank? &&
                  extract_field(ppat, "codt_codfft_#{i}").blank?
        return ppat.matched_cause_codes(i).join(',')
      when 'ons_code1a' # Comma separated ICD codes for death cause 1a
        return extract_field(ppat, 'matched_cause_code_1')
      when 'ons_code1b' # Comma separated ICD codes for death cause 1b
        return extract_field(ppat, 'matched_cause_code_2')
      when 'ons_code1c' # Comma separated ICD codes for death cause 1c
        return extract_field(ppat, 'matched_cause_code_3')
      when 'ons_code2' # Comma separated ICD codes for death cause 2
        return extract_field(ppat, 'matched_cause_code_4')
      when 'ons_code'
        # Concatenate additional cause codes, if present
        # ONS quirks mode: cause 5 is only extracted if 6 is also present
        return '' unless extract_field(ppat, 'matched_cause_code_6').present?
        val = [5, 6].collect { |j| extract_field(ppat, "matched_cause_code_#{j}") }.
              select(&:present?).compact.join(',')
        return val.split(',')[0..7].join(',') # Only 8 ICD codes fit into 40 character field
      when /^codt_codfft_([0-9]+)$/ # Prefer CODFFT to CODT, if present
        i = Regexp.last_match(1).to_i
        # LEDR workaround: split long CODFFT_1 into 75 character blocks to support older extracts.
        # In LEDR extracts, CODFFT_1 is often >= 75 characters, and CODFFT_2..CDOFFT_65 are blank
        codfft_1 = ppat.death_data.codfft_1
        return codfft_1[(i - 1) * 75..(i * 75) - 1] if codfft_1 && codfft_1.size > 75

        return death_field(ppat, "codfft_#{i}") || (death_field(ppat, "codt_#{i}") if i <= 5)
      when /^icd_icdf_([0-9]+)$/ # Prefer ICDF to ICD, if present
        i = Regexp.last_match(1).to_i
        return death_field(ppat, "icdf_#{i}") || death_field(ppat, "icd_#{i}")
      when /^icdpv_icdpvf_([0-9]+)$/ # Prefer ICDPVF to ICDPV, if present
        i = Regexp.last_match(1).to_i
        return death_field(ppat, "icdpvf_#{i}") || death_field(ppat, "icdpv_#{i}")
      when 'icdu_icduf' # Prefer ICDUF to ICDU, if present
        return death_field(ppat, 'icduf') || death_field(ppat, 'icdu')
      when 'icdsc_icdscf' # Prefer ICDSCF to ICDSC, if present
        return death_field(ppat, 'icdscf') || death_field(ppat, 'icdsc')
      when /^multiple_cause_code_([0-9]+)$/
        # ICD10F if present, else ICD10PVF, else ICD10, else ICD10PV
        i = Regexp.last_match(1).to_i
        return ppat.multiple_cause_code(i)
      when 'pod_in_england' # 1 if the place of death is in England, 0 otherwise
        ccg9pod = ppat.death_data['ccg9pod']
        pod_in_england = if ccg9pod
                           ccg9pod.to_s.start_with?('E')
                         else
                           # ppat.death_data['gorr'] != 'W'
                           # https://www.ons.gov.uk/methodology/geography/ukgeographies/administrativegeography/england
                           %w[A B C D E F G H J K].include?(ppat.death_data['gorr'])
                         end
        return pod_in_england ? 1 : 0
      when 'sex_statistical' # If SEX=3 (indeterminate), set to 1.
        val = death_field(ppat, 'sex')
        return val == '3' ? '1' : val
      when 'sexrss' # SEXRSS from regs file (M = male, F = female)
        val = death_field(ppat, 'sex')
        # Doing the same as for cancer deaths, i.e. if SEX=3 (indeterminate), set to 1.
        val = '1' if val == '3'
        return { '1' => 'M', '2' => 'F', '3' => '' }[val] # TODO: What to do with indeterminate sex?
      # Fixes to support migration from old M204 data to new LEDR data
      when 'gor1r' # 1-character GOR field; works for old M204 / new LEDR data
        return GeographicMappingConstants::GOR_MAPPING[death_field(ppat, 'gor9r')] ||
               death_field(ppat, 'gorr')
      when 'mbisid'
        return death_field(ppat, 'ledrid') || death_field(ppat, 'mbism204id')
      when 'patientid' # Linkage identifier for extracting matched patient records
        return @ppatid_rowids[ppat.id]
      end
      val = death_field(ppat, field)
      val
    end
  end
end
