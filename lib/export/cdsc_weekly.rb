module Export
  # Export and de-pseudonymises weekly CDSC data
  # Specification file: "Weekly Cause Utility - CDSC outputs V6  MBIS  (1).pdf"
  class CdscWeekly < DeathFile
    # Map surveillance code to death cause code regular expressions
    SURVEILLANCE_CODES = {
      'CDSC01' => [ # Meningitis
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex']
        ['A81.0', 'Creutzfeldt-Jakob disease', '0', 'A810'],
        ['A81.1', 'Subacute sclerosing panencephalitis', '1', 'A811'],
        ['B01.0', 'Varicella meningitis', '0', 'B010'],
        ['B02.1', 'Zoster meningitis', '1', 'B021'],
        ['B05.1', 'Measles complicated by meningitis', '1', 'B051'],
        ['B26.1', 'Mumps meningitis', '1', 'B261'],
        ['B00.3', 'Herpesviral meningitis', '3', 'B003'],
        ['B00.4', 'Herpesviral encepehalitis', '4', 'B004'],
        ['J14', 'Pneumonia due to Haemophilus influenza', '', 'J14'],
        ['A39', 'Meningococcal infection', '0-5, 8, 9', 'A39[0-589]'],
        ['A86', 'Unspecified viral encephalitis', '', 'A86'],
        ['A87', 'Viral meningitis', '0-2, 8, 9', 'A87[0-289]'],
        # Old ONS extract seems to include G001, even though the spec says not to, and it's in
        # CDSC02 as well
        # ['G00', 'Bacterial meningitis, not elsewhere classified, query inclusion of G001',
        #  '2-3, 8-9', 'G00[2-389]'],
        ['G00', 'Bacterial meningitis, not elsewhere classified, query inclusion of G001',
         '2-3, 8-9', 'G00[1-389]'],
        ['G02', 'Meningitis in other infections and parasitic diseases classified elsewhere',
         '0-1, 8', 'G02[0-18]'],
        ['G03*', 'Meningitis due to other unspecified causes', '0-2, 8, 9', 'G03[0-289]'],
        ['A82', 'Rabies', '0-2, 9', 'A82[0-29]'],
        ['A85', 'Other viral encephalitis, not elsewhere classified', '0-2, 8', 'A85[0-28]'],
        ['A88', 'Other viral infections of central nervous system, not elsewhere classified',
         '0-1, 8', 'A88[0-18]'],
        ['A89', 'Unspecified viral infection of central nervous system', '', 'A89'],
        ['G04', 'Encephalitis, myelitis and encephalomyelitis', '0-2, 8, 9', 'G04[0-289]'],
        ['J11.0', 'Influenza with pneumonia, virus not identified', '0', 'J110'],
        ['J11.1', 'Influenza with other respiratory manifestation virus not identified',
         '1', 'J111']
      ],
      'CDSC02' => [ # Vaccine preventables
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['P35.0', 'Congenital rubella syndrome', '0', 'P350'],
        ['P35.8', 'Other congenital viral diseases', '8', 'P358'],
        ['A33', 'Tetanus neonatorum', '', 'A33'],
        ['B96.3', 'Haemophilus influenza as the cause of diseases classified to other chapters',
         '3', 'B963'],
        ['A49.2', 'Haemophilus influenza infection, unspecified', '2', 'A492'],
        ['G00.0', 'Haemophilus meningitis', '0', 'G000'],
        ['A41.3', 'Septicaemia due to Haemophilus influenza', '3', 'A413'],
        ['J05.1', 'Acute obstructive laryngitis (croup)', '1', 'J051'],
        ['A36', 'Diphtheria', '0-3, 8, 9', 'A36[0-389]'],
        ['A37', 'Whooping cough', '0-1, 8, 9', 'A37[0-189]'],
        ['A80', 'Acute poliomyelitis', '0-4, 9', 'A80[0-49]'],
        ['B01', 'Varicella (chickenpox)', '1, 2, 8, 9', 'B01[1289]'],
        ['B02', 'Zoster (herpes zoster)', '0, 2-3, 7-9', 'B02[0237-9]'],
        ['B05', 'Measles', '0, 2-4, 8, 9', 'B05[02-489]'],
        ['B08', 'Other viral infections characterized by skin and mucous membrane lesions, nec',
         '0-5, 8', 'B08[0-58]'],
        ['B26', 'Mumps', '0-3, 8,9', 'B26[0-389]'],
        ['Y58', 'Bacterial vaccines', '0-6, 8,9', 'Y58[0-689]'],
        ['Y59', 'Other and unspecified vaccines and biological substances',
         '0-3, 8,9', 'Y59[0-389]'],
        ['B15', 'Acute hepatitis A', '0,9', 'B15[09]'],
        ['B16', 'Acute hepatitis B', '0-2, 9', 'B16[0-29]'],
        ['B17', 'Other acute viral hepatitis', '0-2, 9', 'B17[0-29]'],
        ['B18', 'Chronic viral hepatitis', '0-2, 8,9', 'B18[0-289]'],
        ['B19', 'Unspecified viral hepatitis', '0,9', 'B19[09]'],
        ['A34', 'Obstetrical tetanus', '', 'A34'],
        ['A35', 'Other tetanus', '', 'A35'],
        ['A40.3', 'Septicaemia due to streptococcus pneumonia', '3', 'A403'],
        ['B06', 'Rubella', '0, 8-9', 'B06[089]'],
        ['G00.1', 'Pneumococcal meningitis', '1', 'G001'],
        ['P35.1', 'Congenital cytomegalovirus infection', '1', 'P351'],
        ['P35.2', 'Congenital herpesviral (herpes simplex) infection', '2', 'P352'],
        ['P35.3', 'Congenital viral hepatitis', '3', 'P353'],
        ['T88.0', 'Infection following immunization', '0', 'T880'],
        ['T88.1', 'Other complications following immunization NEC', '1', 'T881'],
        ['U07.1', '2019-nCoV acute respiratory disease', '1', 'U071']
      ],
      'CDSC03' => [ # HIV - STI
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['A50', '', '0-7, 9', 'A50[0-79]'],
        ['A51', 'Early syphilis', '0-5, 9', 'A51[0-59]'],
        ['A52', 'Late syphilis', '0-3, 7-9', 'A52[0-37-9]'],
        ['A53', 'Other and unspecified syphilis', '0,9', 'A53[09]'],
        ['A54', 'Gonococcal infection', '0-6, 8,9', 'A54[0-689]'],
        ['C91.5', 'Adult T-cell leukaemia', '5', 'C915'],
        ['G04.1', 'Tropical spastic paraplegia', '1', 'G041']
      ],
      'CDSC04' => [ # Respiratory
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex', 'MaxAge'],
        ['A15', 'Respiratory tuberculosis, bacteriologically and histologically confirmed',
         '0-9', 'A15'],
        ['A16', 'Respiratory tuberculosis, not confirmed bacteriologically or histologically',
         '0-9', 'A16'],
        ['A17', 'Tuberculosis of nervous system', '0-1, 8, 9', 'A17[0189]'],
        ['A18', 'Tuberculosis of other organs', '0-8', 'A18[0-8]'],
        ['A19', 'Military disease', '0-2, 8, 9', 'A19[0-289]'],
        ['A48.1', "Legionnaire's disease", '1', 'A481'],
        ['A48.2', "Nonpneumonic legionnaire's disease (Pontiac fever)", '2', 'A482'],
        ['J10', 'Influenza due to identified influenza virus',
         '0-1, 8 (under 19 years only)', 'J10[018]', 18],
        ['J11', 'Influenza, virus not identified', '0-1, 8 (under 19 years only)', 'J11[018]', 18],
        ['U07.1', '2019-nCoV acute respiratory disease', '1', 'U071']
      ],
      'CDSC05' => [ # Streptococcal bacteraemias
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['A04', 'Enterocolitis due to Clostridium difficile', '7', 'A047'],
        ['A40', 'Streptococcal septicaemia', '0-3, 8, 9', 'A40[0-389]'],
        ['A41', 'Other septicaemia due to Staphylococcus', '0-2 (moved from CDSC08)', 'A41[0-2]'],
        ['A49', 'Unspecified Staphylococcal/Streptococcal infection', '0-1', 'A49[01]'],
        ['J15', 'Pneumonia due to staphylococcus/streptococcuss B/other streptococci',
         '2-4', 'J15[2-4]']
      ],
      'CDSC06' => [ # Gastrosurveillance
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['A00', 'Cholera', '0-1,9', 'A00[019]'],
        ['A01', 'Typhoid and paratyphoid fevers', '0-4', 'A01[0-4]'],
        ['A02', 'Other salmonella infections', '0-2, 8, 9', 'A02[0-289]'],
        ['A03', 'Shingellosis', '0-3, 8, 9', 'A03[0-389]'],
        ['A04', 'Other bacterial intestinal infections', '0-9', 'A04'],
        ['A05', 'Other bacterial foodborne intoxications', '0-4, 8, 9', 'A05[0-489]'],
        ['A06', 'Amoebiasis', '0-9', 'A06'],
        ['A07', 'Other protozoal intestinal diseases', '0-3, 8, 9', 'A07[0-389]'],
        ['A08', 'Viral and other specified intestinal infections', '0-5', 'A08[0-5]'],
        ['A32', 'Listeriosis', '0, 1, 7-9', 'A32[017-9]']
      ],
      'CDSC07' => [ # Travel zoonosis
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['A20', 'Plague', '0-3, 7-9', 'A20[0-37-9]'],
        ['A21', 'Tularaemai', '0-3, 7-9', 'A21[0-37-9]'],
        ['A22', 'Anthrax', '0-2, 7-9', 'A22[0-27-9]'],
        ['A23', 'Brucellosis', '0-3, 8, 9', 'A23[0-389]'],
        ['A24', 'Glanders and melioidosis', '0-4', 'A24[0-4]'],
        ['A27', 'Leptospirosis', '0, 8-9', 'A27[089]'],
        ['A28', 'Other zoonotic bacterial diseases, not elsewhere classified',
         '0-2, 8, 9', 'A28[0-289]'],
        ['A75', 'Typhus fever', '0-3, 9', 'A75[0-39]'],
        ['A78', 'Q fever', '', 'A78'],
        ['A83', 'Mosquito-borne viral encephalitis', '0-6, 8, 9', 'A83[0-689]'],
        ['A90', 'Dengue fever (classical dengue)', '', 'A90'],
        ['A91', 'Dengue haemorrhagic fever', '', 'A91'],
        ['A92', 'Other mosquito-borne viral fevers', '0-4, 8, 9', 'A92[0-489]'],
        ['A94', 'Unspecified arthropod-borne viral fever', '', 'A94'],
        ['A95', 'Yellow fever', '0-1, 9', 'A95[019]'],
        ['A96', 'Arenaviral haemorrhagic fever', '0-2, 8, 9', 'A96[0-289]'],
        ['A98', 'Other viral haemorrhagic fevers, not elsewhere classified', '0-5, 8', 'A98[0-58]'],
        ['A99', 'Unspecified viral haemorragic fever', '', 'A99'],
        ['B03', 'Smallpox', '', 'B03'],
        ['B04', 'Monkeypox', '', 'B04'],
        ['B50', 'Plasmodium falciparum malaria', '0,8,9', 'B50[089]'],
        ['B51', 'Plasmodium vivax malaria', '0,8,9', 'B51[089]'],
        ['B52', 'Plasmodium malariae malaria', '0,8,9', 'B52[089]'],
        ['B53', 'Other parasitologically confirmed malaria', '0-1, 8', 'B53[018]'],
        ['B54', 'Unspecified malaria', '', 'B54'],
        ['B55', 'Leishmaniasis', '0-2, 9', 'B55[0-29]'],
        ['B56', 'African trypanosomiasis', '0-1, 9', 'B56[019]']
      ],
      'CDSC08' => [ # Other
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['A40.9', 'Streptococcal septicaemia, unspecified', '9', 'A409'],
        ['J15.4', 'Pneumonia due to other streptococci', '4', 'J154'],
        ['J17.0', 'Pneumonia in bacterial diseases classified elsewhere', '0', 'J170'],
        ['J02.0', 'Streptococcal pharyngitis', '0', 'J020'],
        ['J02.9', 'Acute pharyngitis, unspecified', '9', 'J029'],
        ['G93.7', "Reye's syndrome", '7', 'G937'],
        ['P37', 'Other congenital infectious and parasitic diseases (congenital falciparum ' \
                'malaria and other c.malaria)', '3, 4', 'P37[34]'],
        ['O98.6', 'Protozoal diseases complicating pregnancy, childbirth and the puerperium',
         '6', 'O986'],
        ['A48.3', 'Toxic shock syndrome', '3', 'A483'],
        ['A46', 'Erysipelas', '', 'A46'],
        ['B95', 'Streptococcus and staphylococcus as the cause of diseases classified to ' \
                'other chapters', '0-8', 'B95[0-8]'],
        ['A41', 'Other septicaemia', '3-5, 8, 9', 'A41[3-589]']
      ],
      'CDSC09' => [ # Pneumonia and Bronchitis
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['J18', 'Pneumonia,organism unspecified', '0 - 2, 8, 9', 'J18[0-289]'],
        ['J20', 'Acute Bronchitis', '0-9', 'J20'],
        ['J21', 'Acute bronchiolitis', '0. 8. 9', 'J21[089]']
      ],
      'CDSC10' => [ # Swine Flu
        # ['ICD Category', 'Description', 'Fourth digit', 'Regex'],
        ['J09', 'Swine Flu', '', 'J09']
      ]
    }.freeze

    def initialize(filename, e_type, ppats)
      super
      @surveillance_codes = SURVEILLANCE_CODES.keys
      @surveillance_patterns = SURVEILLANCE_CODES.collect do |code, entries|
        [code, self.class.site_pattern_re(entries.collect { |rec| rec[3] })]
      end.to_h
      @surveillance_pattern_ages = SURVEILLANCE_CODES.collect do |code, entries|
        next unless entries.any? { |rec| rec[4] }
        [code, entries.collect { |rec| [self.class.site_pattern_re([rec[3]]), rec[4]] }]
      end.compact.to_h
    end

    # Export data to file, returns number of records emitted
    def export
      i = 0
      CSV.open(@filename, 'wb', **csv_options) do |csv|
        header_rows.each { |row| csv << row }
        meth = @ppats.respond_to?(:find_each) ? :find_each : :each
        @ppats.includes(:death_data, :ppatient_rawdata).send(meth) do |ppat|
          @surveillance_codes.each do |code|
            row = extract_row(ppat, i + 1, code)
            if row
              csv << row
              i += 1
            end
          end
        end
        # Print footer rows
        footer_rows(i).each { |row| csv << row }
      end
      i
    end

    # Returns a regular expression matching death site codes, from
    # an array of string site patterns, e.g. ['C44', 'C43[0-5]']
    def self.site_pattern_re(sites)
      Regexp.new("^(#{sites.join('|')})")
    end

    # Returns an array of filename format pattern, for output (e.g. csv or txt file),
    # summary file and zip file [fname, fname_summary, fname_zip]
    # filter is the extract type filter
    # period is :weekly or :monthly or :annual
    def self.fname_patterns(_filter, period)
      case period
      when :weekly
        %w[CDSCWK%W_MBIS.TXT CDSCWK%WP_MBIS.TXT CDSC%Y%m%d_MBIS.zip]
      when :monthly
        %w[CDSC%Y-%mD_MBIS.TXT CDSC%Y-%mP_MBIS.TXT CDSC%Y-%m_MBIS.zip]
      when :annual
        %w[CDSC%YD.TXT CDSC%YP_MBIS.TXT CDSC%Y_MBIS.zip]
      else raise "Unknown period #{period}"
      end
    end

    private

    # Does this row match the given surveillance code?
    # Records selected will be current statistical records (RECTYPE=1),
    # registered from 1/1/2007 onwards (01/11/2007 for CDSC09 and 01/01/2008
    # for CDSC10) and, where ICD10 code (mentions or underlying, most recent
    # code - original or final) fits the selection criteria list and the case
    # has not been sent CDSC before under that surveillance (as determined from
    # an ICD10 "already-output" file or the CDSC9IND).
    def match_row?(ppat, surveillance_code)
      pattern = @surveillance_patterns[surveillance_code]
      icd_fields = (1..8).collect { |i| ["icdf_#{i}", "icdpvf_#{i}"] }.flatten + %w(icduf)
      # Check only final codes, if any present, otherwise provisional codes
      if icd_fields.none? { |field| ppat.death_data[field].present? }
        icd_fields = (1..8).collect { |i| ["icd_#{i}", "icdpv_#{i}"] }.flatten + %w(icdu)
      end
      return false if icd_fields.none? { |field| ppat.death_data[field] =~ pattern }
      pattern_ages = @surveillance_pattern_ages[surveillance_code]
      return true unless pattern_ages # No age filters to consider
      pattern_ages.any? do |pattern2, age|
        icd_fields.any? do |field|
          if ppat.death_data[field] =~ pattern2
            next true if age.nil?
            ppat.unlock_demographics('', '', '', :export) # Unlock only when age is needed
            ppat.age_in_years <= age
          end
        end
      end
    end

    def extract_row(ppat, _i, surveillance_code)
      return unless match_row?(ppat, surveillance_code)
      return if already_extracted?(ppat, surveillance_code)
      ppat.unlock_demographics('', '', '', :export)
      # Simple fields to extract, without special processing
      fields = %w(regs regsd2 regnadm regno entno) + # Not present in MBIS
               %w(fnamd1 fnamd2 fnamd3 fnamdx_1) + # ??? Concatenate extra fnamdx values?
               %w(snamd aliasd_all) + # Concatenate all aliases
               %w(namemaid sexrss dob_ddmmyy dod_ddmmyy ageu1d podt podqual
                  podqualt) + # Not present in MBIS
               %w(dester addrdt pcdr pobt occtype occdt occmt occhft occfft_1 namehf namem) +
               %w(namehfqt codprind) + # Not present in MBIS
               (1..8).collect { |i| "codt_codfft_#{i}" } + # Prefer CODFFT to CODT, if present
               %w(certifer_corcertt) +
               %w(corcertt_2 corcertt_3 corcertt_4) + # Not present in MBIS
               %w(inqcert) +
               %w(fnami snami) + # Not present in MBIS
               %w(namec) +
               %w(desigc) + # Not present in MBIS
               %w(corareat doinqt) +
               %w(inqcertt infqual infqualt relation) + # Not present in MBIS
               %w(addrit signi regsn regsdln signr) + # Not present in MBIS
               %w(desigr) + # Not present in MBIS
               %w(dor) +
               %w(dorqual) + # Not present in MBIS
               %w(ctrypob cestrss ceststay) +
               %w(cbc miscinfo) + # Not present in MBIS
               %w(indhft inddmt emprsshf emprssdm postmort) +
               %w(icdu_icduf) +
               # ICD10F if present, else ICD10PVF, else ICD10, else ICD10PV
               (1..8).collect { |i| "multiple_cause_code_#{i}" } +
               %w(wigwo10) + # Wigglesworth code field wigwo10 intentionally blank in M204 output.
               # %w(nhsno_1) # CDSC extract contains NHSNORSS, not NHSNO_1
               %w(nhsnorss)
      fields.collect { |field| extract_field(ppat, field) } + [surveillance_code]
    end

    # Emit the value for a particular field, including extract-specific tweaks
    def extract_field(ppat, field)
      # Special fields not in the original spec
      case field
      when 'regs', 'regsd2', 'regnadm', 'regno', 'entno', 'podqualt', 'namehfqt', 'codprind',
           'corcertt_2', 'corcertt_3', 'corcertt_4', 'fnami', 'snami', 'desigc',
           'inqcertt', 'infqual', 'infqualt', 'relation',
           'addrit', 'signi', 'regsn', 'regsdln', 'signr', 'desigr',
           'dorqual', 'cbc', 'miscinfo', 'wigwo10'
        return '' # Not present in MBIS
      when 'aliasd_all' # Concatenate all aliases, truncate to 74 characters
        return [super(ppat, 'aliasd_1'), super(ppat, 'aliasd_2')].compact.join(' ')[0..73]
      when 'certifer_corcertt'
        return death_field(ppat, 'certifer') || death_field(ppat, 'corcertt')
      end
      val = super(ppat, field)
      case field
      when 'ctrypob' # Country code tweak for weekly CDSC extract: 3 spaces
        val = '   ' if val == '969'
      when 'addrdt', 'podt' # Truncated to 75 characters in weekly CDSC extract
        val = val[0..74] if val
      end
      val.gsub!("\n", ' ') if val&.is_a?(String) # CDSC won't accept embedded newlines in CSV files
      val
    end
  end
end
