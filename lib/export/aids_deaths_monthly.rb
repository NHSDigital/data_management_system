module Export
  # Export and de-pseudonymise monthly AIDS death data
  # Specification file: "BD009 - Monthly AIDS extract - Angela preparing for sending to .pdf"
  # This is usually run on the second Wednesday of each month.
  class AidsDeathsMonthly < DeathFile
    SURVEILLANCE_CODES = { 'aids99' => /
                             ^(B20[0-9]|B21[0-9]|B22[0-9]|B23[0-9]|B24|B25[0-9]|B371|B375|B582|
                               B59|C46[0-9]|F024|G052|J171|K770|K871|R75|Z21) # AIDS deaths
                           /x }.freeze

    def initialize(filename, e_type, ppats, filter = 'aids99')
      super
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w(icduf)
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w(icdu)
      @fields1 = %w(id21 dod podt snamd fnamd1 fnamd2 fnamd3 sex dob pobt occdt addrdt) +
                 (1..6).collect { |i| "codt_codfft_#{i}" } + %w(dor certifer corcertt corcertt2) +
                 (1..5).collect { |i| "icd_icdf_#{i}" } +
                 (1..5).collect { |i| "icdpv_icdpvf_#{i}" } + %w(namecon blank)
      # Field corcertt2 is not present in MBIS
    end

    private

    def csv_options
      { col_sep: '|', row_sep: "\r\n" }
    end

    # Should this row be extracted? From the original ONS specification:
    # Records selected will be current fully-coded Statistical records
    # (RECTYPE=1 and FCRECIND=1), registered from 1/1/2001 onwards, where ICD10
    # code (mentions or underlying, most recent code - original or final) fits
    # the selection criteria and the case has not been sent to CDSC before
    # under ICD10 (as determined from an ICD10 "already-output" file).
    # The program will find all records on the Stats file group (PPABSTGP)
    # which meet the following criteria:- RECTYPE=1 and
    # FCRECIND=1 and
    # DOR is alpha GE 20010101 (or in an agreed range) and
    # the ICD10 or ICD10PV code is included in the following range of codes: -
    # B20*, B21*, B22*, B23*, B24, B25*, B37.1, B37.5, B58.2, B59, C46*, F02.4,
    # G05.2, J17.1, K77.0, K87.1, R75, Z21 (* represents any digit)
    def match_row?(ppat, _surveillance_code = nil)
      return false unless ppat.death_data.dor >= '20010101'
      pattern = SURVEILLANCE_CODES[@filter]
      icd_fields = @icd_fields_f
      # Check only final codes, if any present, otherwise provisional codes
      icd_fields = @icd_fields if icd_fields.none? { |field| ppat.death_data.send(field).present? }
      return false if icd_fields.none? { |field| ppat.death_data.send(field) =~ pattern }
      true
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      return if already_extracted?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      @fields1.collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'id21'
        ledrid = death_field(ppat, 'ledrid')
        return ledrid unless ledrid.blank?
        # Reconstruct old 19-21 character HPAMT ID field form MBISM204ID
        s = death_field(ppat, 'mbism204id')
        s = s[0..2] + ' ' + s[3..17] + ' ' + s[18..-1] if s.size == 28 # uncompact blanks
        # return (s[25..27] + s[2..3] + s[18..19] + s[20..22] + s[13..15]).delete(' ') + ' ' + s
        return (s[25..27] + s[2..3] + s[18..19] + s[20..22] + s[13..15]).delete(' ')
      when 'blank'
        return nil # Dummy empty field at the end
      when 'corcertt2'
        return nil # Not present in MBIS
      end
      val = super(ppat, field)
      case field
      when 'addrdt', 'podt', 'pobt' # Truncated to 75 characters in monthly AIDS extract
        val = val[0..74] if val
      when 'certifer' # Truncated to 40 characters
        val = val[0..39] if val
      end
      # Original file contained inconsistent single space fields (especially in CODT)
      # val ||= ' ' unless field =~ /^codt/ # Replace all empty fields with single spaces
      val
    end
  end
end
