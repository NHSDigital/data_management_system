module Export
  # Export and de-pseudonymise annual KIT death extract
  # Specification file: "PHE K&IS DEATHS 2016.pdf"
  class KitDeathsFile < DeathFileSimple
    private

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: true }
    end

    def fields
      # Simple fields to extract, without special processing
      fields1 = %w[dob dod agec agecunit pcdr cestrss esttyped creg_occ90dm creg_occ90hf
                   hautr hautpod dor sex_statistical] + (1..15).collect { |i| "icdpv_#{i}" } +
                %w[icdu wigwo10 icdsc ctyr ctydr wardr neonatal creg_pcdind
                   gorr hror indefinite_date_of_birth ctrypob retindm retindhf]
      # Wigglesworth code field wigwo10 is intentionally blank in M204 output.
      # #extract_row suppresses cod10r_... for non-neonatal patients in old Model 204 extracts
      fields2_neonates = (1..15).collect { |i| "cod10r_#{i}" } # neonates only (in Model 204)
      fields3 = (1..15).collect { |i| "icd_#{i}" } + # non-neonates
                (1..15).collect { |i| "lineno9_#{i}" } +
                %w[soc2kdm soc2khf] +
                %w[podt pcdpod] + # Extra fields in KitDeaths, not in cancer registry file
                %w[ctyra ctydra gorra wardra] # All blank 2013/14 onwards, cf. #extract_field
      # The 4 'space2' fields are:
      # - CTYRA: 2009 onward - blank 2013/14 onwards
      # - CTYDRA: 2009 onward - blank 2013/14 onwards
      # - GORRA: 2009 onward - blank 2013/14 onwards
      # - WARDRA: 2009 onward - blank 2013/14 onwards

      # Extra fields in KitDeaths, not in cancer registry file
      fields4 = (1..5).collect { |i| "codt_codfft_#{i}" } + %w[nhsind seccatdm seccathf lsoar]
      fields1 + fields2_neonates + fields3 + fields4
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'neonatal'
        return ppat.neonatal? ? '1' : ''
      when 'indefinite_date_of_birth'
        return ppat.indefinite_date_of_birth? ? '1' : ''
      when 'creg_occ90dm', 'creg_occ90hf'
        return '   ' # Spaces 2013/2014 onwards instead of OCC90DM and OCC90HF
      when 'ctyra', 'ctydra', 'gorra', 'wardra'
        return '  ' # All blank 2013/14 onward
      when 'space1'
        return ' '
      when 'blank'
        return '' # TODO: Refactor into DeathFile
      when 'creg_pcdind' # PCDIND not extracted for MBIS
        return ''
      when /^lineno9_/
        return '' if ppat.neonatal? # Suppress these fields for neonatal patients
      when /^cod10r_([0-9]+)$/
        # Suppress these fields for non-neonatal patients in old Model 204 extracts
        return '' unless ppat.demographics['ledrid'] || ppat.neonatal?
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
      when 'podt' # Truncated to 75 characters in annual KITDEATHS extract
        val = val[0..74] if val
      when 'icdu' # KITDEATHS wants this for non-neonates only
        val = nil if ppat.neonatal?
      end
      val = val.gsub('"', '  ')[0..74] if val && val =~ /"/ # Double quotes to 2 spaces, <= 75 char
      val
    end
  end
end
