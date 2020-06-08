module Export
  # Export and de-pseudonymise annual CDSC death extract
  # Specification file: "BD027 - Infectious Diseases - AKA CDSCRG16 Angela Prepared for .pdf"
  class CdscMortalityFile < DeathFile
    # The program finds all deaths records from the requested date range (ie registered in the
    # required quarter) and there is a mention of Z226(HTLV), C915(ATTL) or G041(TSP).
    # R95 is specified as one of the ICD codes to match, but only R959 is a valid code,
    # and the historical extract from ONS did not include this.
    # SURVEILLANCE_PATTERN_UNDERLYING = /^([AB]|G0[0-9]|J0[0-69]|J1[0-8]|J2[0-2]|J4[012]|L0[0-8]|M729|O8[5-9]|O9[0-28]|P002|P3[5-9]|R95)/
    SURVEILLANCE_PATTERN_UNDERLYING = /^([AB]|G0[0-9]|J0[0-69]|J1[0-8]|J2[0-2]|J4[012]|L0[0-8]|M729|O8[5-9]|O9[0-28]|P002|P3[5-9])/
    SURVEILLANCE_PATTERN_MULTIPLE_CAUSES = /^([AB]|G0[0-9]|J09|J05[0-1]|J1[0-4]|J21|J40|M729|O8[5-9]|O9[0-28]|P002|P008|P3[5-9]|T6[24]|Y5[89]|T509)/
    SURVEILLANCE_PATTERN_NEONATAL = /^([AB]|G0[09]|J09|J05[0-1]|J1[0-4]|J40|M729|N76|O8[5-9]|O9[0-2]|O98|P002|P008|P23|P3[5-9]|T61)/

    def initialize(filename, e_type, ppats, filter = nil)
      super
      @icd_fields_underlying = %w(icduf icdu)
      @icd_fields_multiple = (1..20).collect { |i| ["icdf_#{i}", "icd_#{i}"] }.flatten
      @icd_fields_neonatal = (1..20).collect { |i| ["icdpvf_#{i}", "icdpv_#{i}"] }.flatten
      fields1 = %w(mbism204id doddy dodmt dodyr podt podqual podqualt dester dor corareat hautr
                   sex_statistical agec_agecunit postmort icdu icduf)
      fields2 = (1..5).collect { |i| "cod10r_#{i}" } + (1..5).collect { |i| "cod10rf_#{i}" }
      @fields = fields1 + (1..5).collect { |i| "icd_#{i}" } + (1..5).collect { |i| "icdf_#{i}" } +
                (1..5).collect { |i| "codt_codfft_#{i}" } + (1..10).collect { 'blank' }
      @fields_neonatal = fields1 + (1..5).collect { |i| "icdpv_#{i}" } +
                         (1..5).collect { |i| "icdpvf_#{i}" } +
                         (1..5).collect { |i| "codt_codfft_#{i}" } + fields2
    end

    private

    def footer_rows(i)
      [[Date.today.strftime('%Y%m%d'), i]]
    end

    def csv_encoding
      'windows-1252:utf-8'
    end

    def csv_options
      { col_sep: 0x9c.chr.force_encoding('Windows-1252'), row_sep: "\r\n" }
    end

    def match_row?(ppat, _surveillance_code = nil)
      return true if @icd_fields_underlying.any? do |field|
        ppat.death_data.send(field) =~ SURVEILLANCE_PATTERN_UNDERLYING
      end
      return true if @icd_fields_multiple.any? do |field|
        ppat.death_data.send(field) =~ SURVEILLANCE_PATTERN_MULTIPLE_CAUSES
      end
      @icd_fields_neonatal.any? do |field|
        ppat.death_data.send(field) =~ SURVEILLANCE_PATTERN_NEONATAL
      end
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      (ppat.neonatal? ? @fields_neonatal : @fields).collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'agec_agecunit'
        return %w(agec agecunit).collect { |f| extract_field(ppat, f) }.join
      end
      val = super(ppat, field)
      case field
      when 'podt' # Truncated to 75 characters
        val = val[0..74] if val
      end
      val
    end
  end
end
