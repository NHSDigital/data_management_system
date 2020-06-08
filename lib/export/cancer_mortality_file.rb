module Export
  # Export and de-pseudonymise annual cancer registry death statistics extract
  # Specification file: "ONS Annual Mortality Extract for Cancer Registries.docx"
  class CancerMortalityFile < DeathFile
    def initialize(filename, e_type, ppats, filter = nil)
      super
      # Simple fields to extract, without special processing
      fields1 = %w(dob dod agec agecunit pcdr cestrss esttyped creg_occ90dm creg_occ90hf
                   hautr hautpod dor sex) + (1..15).collect { |i| "icdpv_#{i}" } +
                %w(icdu_icduf wigwo10 icdsc ctyr ctydr wardr neonatal creg_pcdind
                   gorr hror indefinite_date_of_birth ctrypob retindm retindhf)
      # Wigglesworth code field wigwo10 is intentionally blank in M204 output.
      fields2_neonates = (1..15).collect { |i| "cod10r_#{i}" } # neonates only ??
      fields3 = (1..15).collect { |i| "icd_#{i}" } + # non-neonates
                (1..15).collect { |i| "lineno9_#{i}" } +
                %w(soc2kdm soc2khf space2 space2 space2 space2)
      # The 4 'space2' fields are:
      # - CTYRA: 2009 onward - blank 2013/14 onwards
      # - CTYDRA: 2009 onward - blank 2013/14 onwards
      # - GORRA: 2009 onward - blank 2013/14 onwards
      # - WARDRA: 2009 onward - blank 2013/14 onwards
      @fields = fields1 + fields2_neonates.collect { |_| 'blank' } + fields3
      @fields_neonatal = fields1 + fields2_neonates + fields3
    end

    private

    def extract_row(ppat, _j)
      ppat.unlock_demographics('', '', '', :export)
      # Rails.logger.warn("#{self.class.name.split('::').last}: Row #{_j}, extracted " \
      #                   "#{ppat.record_reference}")
      # Death cause codes have all moved from 'lineno9' fields to 'cod10r' fields in LEDR
      if ppat.demographics['ledrid']
        return @fields_neonatal.collect { |field| extract_field(ppat, field) }
      end
      # Preserve old behaviour for old Model 204 extracts
      (ppat.neonatal? ? @fields_neonatal : @fields).collect { |field| extract_field(ppat, field) }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'neonatal'
        return ppat.neonatal? ? '1' : ''
      when 'indefinite_date_of_birth'
        return ppat.indefinite_date_of_birth? ? '1' : ''
      when 'creg_occ90dm', 'creg_occ90hf'
        return '   ' # Spaces 2013/2014 onwards instead of OCC90DM and OCC90HF
      when 'space2'
        return '  '
      when 'space1'
        return ' '
      when 'blank'
        return '' # TODO: Refactor into DeathFile
      when 'creg_pcdind' # PCDIND not extracted for MBIS
        return ''
      when /^lineno9_/
        return '' if ppat.neonatal? # Suppress these fields for neonatal patients
      when 'wardr'
        # Support move to LEDR data (2017-onwards), but still handle 2016 data sensibly
        return super(ppat, 'ward9r') || super(ppat, field)
      when 'gorr'
        # Support move to LEDR data (2017-onwards), but still handle 2016 data sensibly
        return super(ppat, 'gor9r') || super(ppat, field)
      end
      val = super(ppat, field)
      case field
      when 'ctrypob' # Country code tweak for annual cancer extract
        val = ' ' if val == '969'
      when 'sex' # If SEX=3 (indeterminate), set to 1.
        val = '1' if val == '3'
      end
      val
    end
  end
end
