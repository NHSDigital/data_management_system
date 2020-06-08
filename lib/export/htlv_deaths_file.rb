module Export
  # Export and de-pseudonymise annual HTLV death extract
  # Specification file: "HTLV Annual Refresh 2016.pdf"
  class HtlvDeathsFile < DeathFile
    # The program finds all deaths records from the requested date range (ie registered in the
    # required quarter) and there is a mention of Z226(HTLV), C915(ATTL) or G041(TSP).
    SURVEILLANCE_PATTERN = /^(Z226|C915|G041)/

    def initialize(filename, e_type, ppats, filter = nil)
      super
      @icd_fields_f = (1..20).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w(icduf)
      @icd_fields = (1..20).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w(icdu)
      @fields1 = %w(snamd fnamd1 fnamd2 fnamd3 fnamdx sex_statistical dob pobt occdt addrdt_last2
                    ctydis dod podt_or_at_home) + (1..6).collect { |i| "codt_codfft_#{i}" } +
                 (1..5).collect { |i| "icd_icdf_#{i}" } +
                 %w(certifer_namec_corcertt namecon mbism204id)
    end

    private

    def csv_encoding
      'windows-1252:utf-8'
    end

    def csv_options
      { col_sep: '|', row_sep: "\r\n", force_quotes: true }
    end

    def match_row?(ppat, _surveillance_code = nil)
      # TODO: Refactor with match_row? in CancerDeathWeekly / CdscWeekly
      pattern = SURVEILLANCE_PATTERN
      icd_fields = @icd_fields_f
      # Check only final codes, if any present, otherwise provisional codes
      icd_fields = @icd_fields if icd_fields.none? { |field| ppat.death_data.send(field).present? }
      return false if icd_fields.none? { |field| ppat.death_data.send(field) =~ pattern }
      true
    end

    def extract_row(ppat, _j)
      return unless match_row?(ppat)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      @fields1.collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'ctydis'
        return %w(ctyr ctydr).collect { |f| extract_field(ppat, f) }.join
      when 'addrdt_last2' # Last 2 words of addrdt
        return ([nil] + extract_field(ppat, 'addrdt').to_s.split(' ').last(2)).join(' ')
      when 'podt_or_at_home'
        return death_field(ppat, 'cestrss') == 'H' ? 'AT HOME' : extract_field(ppat, 'podt')
      when 'certifer_namec_corcertt'
        return death_field(ppat, 'certifer') || death_field(ppat, 'namec') ||
               death_field(ppat, 'corcertt')
      end
      val = super(ppat, field)
      val = val.gsub('"', '  ')[0..74] if val && val =~ /"/ # Double quotes to 2 spaces, <= 75 char
      val
    end
  end
end
