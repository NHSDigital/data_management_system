module Export
  # Export and de-pseudonymise weekly pandemic flu data
  # Specification file: "Annual Pandemic extract - Angela Preparation for MBI.pdf"
  class PandemicFluWeekly < DeathFile
    # Map ICD underlying causes codes to surveillance group
    ICD10GP_CODES = {
      'I' => /^[AB]/, # A00 - B999 inclusive
      'II' => /^(C|D[0-4])/, # C00 - D459 inclusive
      'III' => /^D[5-8]/, # D50 - D899 inclusive
      'IV' => /^E/, # E00 - E909 inclusive
      'V' => /^F/, # F00 - F999 inclusive
      'VI' => /^G/, # G00 - G999 inclusive
      'VII' => /^H[0-5]/, # H00 - H599 inclusive
      'VIII' => /^H[6-9]/, # H60 - H959 inclusive
      'IX' => /^I/, # I00 - I999 inclusive
      'X' => /^J/, # J00 - J999 inclusive
      'XI' => /^K/, # K00 - K939 inclusive
      'XII' => /^L/, # L00 - L999 inclusive
      'XIII' => /^M/, # M00 - M999 inclusive
      'XIV' => /^N/, # N00 - N999 inclusive
      'XV' => /^O/, # O00 - O999 inclusive
      'XVI' => /^P/, # P00 - P969 inclusive
      'XVII' => /^Q/, # Q00- Q999 inclusive
      'XVIII' => /^R/, # R00 - R999 inclusive
      'XIX' => /^[ST]/, # S00 - T989 inclusive
      'XX' => /^[UVWXY]/ # U01 - Y989 inclusive
    }.freeze

    # Returns an array of filename format pattern, for output (e.g. csv or txt file),
    # summary file and zip file [fname, fname_summary, fname_zip]
    # filter is the extract type filter
    # period is :weekly or :monthly or :annual
    def self.fname_patterns(_filter, period)
      case period
      when :weekly
        %w[PAN%y%m%dD_MBIS.TXT PAN%y%m%dP_MBIS.TXT PAN%y%m%d_MBIS.zip]
      when :monthly
        %w[PAN%Y-%mD_MBIS.TXT PAN%Y-%mP_MBIS.TXT PAN%Y-%m_MBIS.zip]
      when :annual
        %w[PAN%YD.TXT PAN%YP_MBIS.TXT PAN%Y_MBIS.zip]
      else raise "Unknown period #{period}"
      end
    end

    private

    def header_rows
      # TODO: Refactor weekly_death_re // method to get batch submission date. cf. export_cdsc.rake
      weekly_death_re = /MBIS(WEEKLY_Deaths_D|_20)([0-9]{6}).txt/
      week = @ppats.first&.e_batch&.original_filename&.match(weekly_death_re) &&
             '20' + Regexp.last_match[2]
      [[' '], ['ONS2DHKWKMORT', "RUN=#{week}"]]
    end

    def footer_rows(i)
      [['ENDOFFILE', "COUNT=#{i}"]]
    end

    def csv_options
      { col_sep: ',', row_sep: "\r\n" }
    end

    # The specification is "All non neonatal records in the requested date range"
    # but the historical weekly files seem to include neonatal records too
    def match_row?(ppat, _surveillance_code = nil)
      # Ignore registrations before 2017, not currently loaded into MBIS
      ppat.death_data['dor'][0..3].to_i >= 2017
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      return if already_extracted?(ppat)
      # Extracts of LEDR data use 9 character codes for CTYR CTYDR, HAUTR, HAUTPOD, CCG9POD
      # Re-extracts of M204 data now use 9 character codes for CCGPOD
      # GOR9R is being back-mapped to the old 1-character code
      fields = %w(dod dor agec agecunit sex icdu3char icd10gp regs gor1r ctyr ctydr hautr hautpod
                  ccg9pod)
      # Field regs is not present in MBIS
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      fields.collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'regs'
        return nil # Not present in MBIS, emit as empty string, not 2 double quotes
      when 'icdu3char' # First 3 characters of ICDU
        icdu = extract_field(ppat, 'icdu_icduf') # Prefer ICDUF to ICDU, if present
        return icdu && icdu[0..2]
      when 'icd10gp'
        icdu = extract_field(ppat, 'icdu_icduf') # Prefer ICDUF to ICDU, if present
        ICD10GP_CODES.each { |group, re| return group if icdu =~ re }
        return nil # No group found
      end
      val = super(ppat, field)
      val
    end
  end
end
