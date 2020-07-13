module Export
  # Export and de-pseudonymise annual KIT death extract
  # Specification file: "PHE K&IS DEATHS 2016.pdf" and https://ncr.plan.io/issues/9205
  # and https://ncr.plan.io/issues/23906
  class KitDeathsFile < DeathFileSimple
    private

    def csv_options
      { col_sep: ',', row_sep: "\r\n", force_quotes: true }
    end

    def fields
      # Add extra fields requested 2020-06
      # Use old fields wherever possible, with minimal tweaks plus extra fields wherever possible
      # Fields in output, not directly requested, kept for consistency of file format:
      #   dob dod neonatal blank_pcdind indefinite_date_of_birth
      #   blank_ctyra blank_ctydra blank_gorra blank_wardra codt_codfft
      # Fields requested, not directly in output:
      #   dobyr dobmt dobdy dodyr dodmt doddy
      # Field name changes:
      # creg_occ90dm => occ90dm # previously blank, now populated from MBIS
      # creg_occ90hf => occ90hf # previously blank, now populated from MBIS
      # creg_pcdind => blank_pcdind # previously blank, not in MBIS, not labelled clearly as blank
      # ctyra => blank_ctyra # previously blank, not in MBIS, not labelled clearly as blank
      # ctydra => blank_ctydra # previously blank, not in MBIS, not labelled clearly as blank
      # gorra => blank_gorra # previously blank, not in MBIS, not labelled clearly as blank
      # wardra => blank_wardra # previously blank, not in MBIS, not labelled clearly as blank
      fields1 = %w[dob dod] + # Derived fields, combine (dobyr dobmt dobdy), (dodyr dobmt dobdy)
                %w[agec agecunit pcdr cestrss esttyped occ90dm occ90hf
                   hautr hautpod dor sex_statistical] + (1..15).collect { |i| "icdpv_#{i}" } +
                %w[icdu wigwo10 icdsc ctyr ctydr wardr] +
                %w[neonatal] + # Derived field, derived from (agec agecunit)
                %w[blank_pcdind] + # Historical field, now blank
                %w[gorr hror] +
                %w[indefinite_date_of_birth] + # Derived field, derived from (dobdy dobmt)
                %w[ctrypob retindm retindhf]
      # Wigglesworth code field wigwo10 is intentionally blank in M204 output.
      # #extract_row suppresses cod10r_... for non-neonatal patients in old Model 204 extracts
      fields2_neonates = (1..15).collect { |i| "cod10r_#{i}" } # neonates only (in Model 204)
      fields3 = (1..15).collect { |i| "icd_#{i}" } + # non-neonates
                (1..15).collect { |i| "lineno9_#{i}" } +
                %w[soc2kdm soc2khf] +
                %w[podt pcdpod] + # Extra fields in KitDeaths, not in cancer registry file
                %w[blank_ctyra blank_ctydra blank_gorra blank_wardra] # Historical fields, now blank
      # The 4 'space2' fields are:
      # - CTYRA: 2009 onward - blank 2013/14 onwards
      # - CTYDRA: 2009 onward - blank 2013/14 onwards
      # - GORRA: 2009 onward - blank 2013/14 onwards
      # - WARDRA: 2009 onward - blank 2013/14 onwards

      # Extra fields in KitDeaths, not in cancer registry file
      fields4 = (1..5).collect { |i| "codt_codfft_#{i}" } + # Special fields
                %w[nhsind seccatdm seccathf lsoar]

      # Extra fields requested 2020-06:
      # Removing the following requested additional fields, as they're directly combined above:
      # dobyr dobmt dobdy dodyr dodmt doddy
      # Keeping old field structure, and adding additional columns
      fields5 = (16..20).collect { |i| "icdpv_#{i}" } + # Extra values not in old extract
                (16..20).collect { |i| "cod10r_#{i}" } + # Extra values not in old extract
                (16..20).collect { |i| "icd_#{i}" } + # Extra values not in old extract
                (16..20).collect { |i| "lineno9_#{i}" } + # Extra values not in old extract
                %w[mbisid ledrid cestrssr ceststay ccgpod cod10rf codt ctydpod ctypod dester
                   hropod icdf icdpvf icdscf icduf icdfuture1 icdfuture2 lineno9f loapod lsoapod
                   ploacc10 podqual wigwo10f addrdt ageu1d ccgr ctryr loar marstat occdt occfft
                   occtype pobt agecs emprssdm emprsshf empsecdm empsechf empstdm empsthf inddmt
                   indhft occhft occmt sclasdm sclashf sec90dm sec90hf secclrdm secclrhf
                   soc90dm soc90hf certtype corareat corcertt doinqt inqcert postmort codfft
                   ccg9pod ccg9r gor9r ward9r]

      all_fields = fields1 + fields2_neonates + fields3 + fields4 + fields5
      all_fields.flat_map do |field|
        special = SPECIAL[field.to_sym]
        special ? special.call : field
      end
    end

    def old_fields
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

    def extra_field_descriptions
      super.merge(
        'dob' => 'Date of birth (yyyymmdd)',
        'dod' => 'Date of death (yyyymmdd)',
        'neonatal' => 'Neonatal flag (1 for neonatal, blank otherwise)',
        'blank_pcdind' => 'Blank (historically PCDIND)',
        'indefinite_date_of_birth' => 'Indefinite date of birth? (1 for yes, blank otherwise)',
        'blank_ctyra' => 'Blank (historically CTYRA)',
        'blank_ctydra' => 'Blank (historically CTYDRA)',
        'blank_gorra' => 'Blank (historically GORRA)',
        'blank_wardra' => 'Blank (historically WARDRA)',
        # Disused columns from old_fields
        'creg_occ90dm' => 'Spaces 2013/2014 onwards instead of OCC90DM',
        'creg_occ90hf' => 'Spaces 2013/2014 onwards instead of OCC90HF',
        'creg_pcdind' => 'PCDIND not extracted for MBIS',
        'ctyra' => 'CTYRA: 2009 onward - blank 2013/14 onwards',
        'ctydra' => 'CTYDRA: 2009 onward - blank 2013/14 onwards',
        'gorra' => 'GORRA: 2009 onward - blank 2013/14 onwards',
        'wardra' => 'WARDRA: 2009 onward - blank 2013/14 onwards'
      )
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
      when /^blank(_.*)?$/
        return '' # TODO: Refactor into DeathFile
      when 'creg_pcdind' # PCDIND not extracted for MBIS
        return ''
      when /^lineno9f?_/
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
      # Double quotes to 2 spaces, <= 75 char
      # val = val.gsub('"', '  ')[0..74] if val && val =~ /"/
      val
    end
  end
end
