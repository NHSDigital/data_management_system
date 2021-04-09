require 'ndr_import/table'
require 'ndr_import/file/registry'

module Import
  # Imports and pseudonymises delimited MBIS data
  class DelimitedFile
    include ImportKey
    DIRECT_DEATH_IDENTIFIERS   = %w(addrdt akfnamd_1_1 akfnamd_1_2 akfnamd_1_3 akfnamd_1_4
                                    akfnamd_1_5 akfnamd_2_1 akfnamd_2_2 akfnamd_2_3 akfnamd_2_4
                                    akfnamd_2_5 akfnamd_3_1 akfnamd_3_2 akfnamd_3_3 akfnamd_3_4
                                    akfnamd_3_5 akfndi_1 akfndi_2 akfndi_3 akfndi_4 akfndi_5
                                    aksnamd_1 aksnamd_2 aksnamd_3 aksnamd_4 aksnamd_5 aliasd_1
                                    aliasd_2 certifer fnamd1 fnamd2 fnamd3 fnamdx_1 fnamdx_2
                                    ledrid mbism204id namec namecon namehf namem namemaid nhsnorss
                                    nhsno_1 nhsno_2 nhsno_3 nhsno_4 nhsno_5 snamd).freeze
    INDIRECT_DEATH_IDENTIFIERS = %w(agec agecs ageu1d dobdy dobmt
                                    dobyr pcdpod pcdr pobt sex).freeze
    NON_IDENTIFYING_DEATH_DATA = (
      %w[agecunit ccg9pod ccg9r ccgpod ccgr certtype cestrss cestrssr ceststay] +
      (1..20).collect { |i| "cod10r_#{i}" } +
      (1..20).collect { |i| "cod10rf_#{i}" } +
      (1..65).collect { |i| "codfft_#{i}" } +
      (1..5).collect { |i| "codt_#{i}" } +
      %w[corareat corcertt ctrypob ctryr ctydpod ctydr ctypod ctyr dester doddy dodmt dodyr doinqt
         dor emprssdm emprsshf empsecdm empsechf empstdm empsthf esttyped gor9r gorr hautpod hautr
         hropod hror] +
        (1..20).collect { |i| "icd_#{i}" } +
      (1..20).collect { |i| "icdf_#{i}" } +
      %w[icdfuture1 icdfuture2] +
        (1..20).collect { |i| "icdpv_#{i}" } +
        (1..20).collect { |i| "icdpvf_#{i}" } +
      %w[icdsc icdscf icdu icduf inddmt indhft inqcert] +
        (1..20).collect { |i| "lineno9_#{i}" } +
        (1..20).collect { |i| "lineno9f_#{i}" } +
      %w[loapod loar lsoapod lsoar marstat nhsind occ90dm occ90hf occdt occfft_1 occfft_2 occfft_3
         occfft_4 occhft occmt occtype ploacc10 podqual podt postmort retindhf retindm sclasdm
         sclashf sec90dm sec90hf seccatdm seccathf secclrdm secclrhf soc2kdm soc2khf soc90dm soc90hf
         ward9r wardr wigwo10 wigwo10f]
    ).freeze

    DIRECT_BIRTH_IDENTIFIERS   = %w(addrmt codfft_1 codfft_2 codfft_3 codfft_4 codfft_5 deathlab
                                    fnamch1 fnamch2 fnamch3 fnamchx_1 fnamchx_2 fnamfx_1 fnamfx_2
                                    fnamf_1 fnamf_2 fnamf_3 fnammx_1 fnammx_2 fnamm_1 fnamm_2
                                    fnamm_3 gestatn icdpvf_1 icdpvf_10 icdpvf_11 icdpvf_12
                                    icdpvf_13 icdpvf_14 icdpvf_15 icdpvf_16 icdpvf_17 icdpvf_18
                                    icdpvf_19 icdpvf_2 icdpvf_20 icdpvf_3 icdpvf_4 icdpvf_5
                                    icdpvf_6 icdpvf_7 icdpvf_8 icdpvf_9 icdpv_1 icdpv_10 icdpv_11
                                    icdpv_12 icdpv_13 icdpv_14 icdpv_15 icdpv_16 icdpv_17 icdpv_18
                                    icdpv_19 icdpv_2 icdpv_20 icdpv_3 icdpv_4 icdpv_5 icdpv_6
                                    icdpv_7 icdpv_8 icdpv_9 ledrid mbism204id namemaid nhsno pobt
                                    sbind snamch snamf snamm snammcf).freeze
    INDIRECT_BIRTH_IDENTIFIERS = %w(dob dobm pcdpob pcdrm sex).freeze

    def initialize(filename, batch)
      @filename = filename
      @batch = batch
    end

    def load
      # Set the EBatch.digest
      insert_e_batch_digest(@batch) if file
      ensure_file_not_already_loaded
      tables = NdrImport::File::Registry.tables(@filename, table_mapping.try(:format),
                                                'col_sep' => table_mapping.try(:delimiter))

      # Enumerate over the tables
      # Under normal circustances, there will only be one table
      tables.each do |_tablename, table_content|
        table_mapping.transform(table_content).each do |klass, fields, index|
          Pseudo::Ppatient.transaction do
            begin
              pseudonymise_and_build_records(klass.constantize, fields)
            rescue RuntimeError => e
              raise "#{e.message} on row #{index + 1}" # index ignores header row
            end
          end
        end
      end
      @batch.save!
    end

    private

    def insert_e_batch_digest(batch)
      batch.update(digest: digest)
    end

    # Get the SHA1 digest of the source
    def digest
      return nil if file.nil?
      @digest ||= Digest::SHA1.file(SafeFile.safepath_to_string(@filename)).hexdigest
    end

    def file
      @file ||= SafeFile.exist?(@filename) ? SafeFile.new(@filename, 'r') : nil
    end

    # Fail early if the source file has already been loaded.
    def ensure_file_not_already_loaded
      clashes = EBatch.where('digest = ? and e_batchid != ?', digest, @batch.id)
      error_message = "Source file already loaded: See e_batchid: #{clashes.map(&:id).join(', ')}"
      raise error_message if clashes.any?
    end

    # Load the required mapping file based on @batch.e_type
    def table_mapping
      # TODO: Decide on e_type names
      # mapping_file = 'death_mapping.yml'
      mapping_file = case @batch.e_type
                     when 'PSDEATH'
                       'deaths_mapping.yml'
                     when 'PSBIRTH'
                       'births_mapping.yml'
                     else
                       raise "No mapping found for #{@batch.e_type}"
                     end

      YAML.load_file(SafePath.new('mappings_config').join(mapping_file))
    end

    # Check that the mappings inherit NdrImport::Table
    def ensure_all_mappings_are_tables
      return if @table_mappings.all? { |table| table.is_a?(NdrImport::Table) }
      raise 'Mappings must be inherit from NdrImport::Table'
    end

    def pseudonymise_and_build_records(klass, fields)
      # Returns hash of demographic_fields and values.
      demographics = fields & demographic_fields
      fields_no_demog = fields & (fields.keys - demographic_fields - [:rawtext])
      if preserve_rawtext
        # TODO: Encrypt separately and store using a second ppatient_rawdata_id to ppatients.
        rawtext = fields[:rawtext]
        raise('Not yet implemented')
      else
        rawtext = nil
      end

      # Automatically skip over footer rows, which ONS sometimes includes (in weekly extracts)
      # and sometimes omits (in annual refreshes)
      if demographics['mbism204id'] =~ /\A(COUNT |Total of Extracted records = )/
        Rails.logger.warn("Skipping footer row: #{demographics['mbism204id'].inspect}")
        return
      end
      raise 'Cannot import header row' if demographics['mbism204id'] =~ /\A(RECORD ID|Record ID)/
      raise 'Cannot import row with no DOR (header/footer?)' if fields_no_demog['dor'].blank?
      # Map nhsnumber, birthdate, postcode appropriately
      case @batch.e_type
      when 'PSBIRTH'
        nhsno_field = 'nhsno'
        dob = if demographics['dob'] =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})\z/
                "#{Regexp.last_match[1]}-#{Regexp.last_match[2]}-#{Regexp.last_match[3]}"
              else
                ''
              end
        postcode_field = 'pcdrm'
      when 'PSDEATH'
        nhsno_field = 'nhsno_1'
        dob = "#{demographics['dobyr']}-#{demographics['dobmt']}-#{demographics['dobdy']}"
        postcode_field = 'pcdr'
      else
        raise "Unknown e_type #{@batch.e_type}"
      end
      demographics['nhsnumber'] = if demographics[nhsno_field] =~ /\A[0-9]{10}\Z/
                                    demographics[nhsno_field]
                                  else
                                    ''
                                  end
      demographics['birthdate'] = dob =~ Pseudo::KeyStoreLocal::DATE_RE ? dob : ''
      postcode = demographics[postcode_field]
      demographics['postcode'] = postcode =~ Pseudo::KeyStoreLocal::POSTCODE_RE ? postcode : ''
      # Pseudonymise `fields`
      # Create the Pseudo::Ppatient and Pseudo::PpatientRawdata records
      ppatient = klass.initialize_from_demographics(key, demographics, rawtext, e_batch: @batch)
      # Create the Pseudo::Ppatient subclass and subclassData records
      case @batch.e_type
      when 'PSBIRTH'
        ppatient.birth_data = Pseudo::BirthData.new(fields_no_demog)
        bad_keys = fields_no_demog.keys - ppatient.birth_data.attributes.keys
        raise("Key missing from Pseudo::BirthData: #{bad_keys.inspect}") if bad_keys.present?
      when 'PSDEATH'
        ppatient.build_death_data(fields_no_demog)
        bad_keys = fields_no_demog.keys - ppatient.death_data.attributes.keys
        raise("Key missing from Pseudo::DeathData: #{bad_keys.inspect}") if bad_keys.present?
      else
        raise "Unknown e_type #{@batch.e_type}"
      end
      if @batch.persisted?
        # Avoid keeping entire batch in memory, and just stream records to database
        ppatient.e_batch_id = @batch.id
        begin
          ppatient.save!
        rescue ActiveRecord::RecordInvalid => e
          puts "Validation error: mbism204id #{demographics['mbism204id'].inspect}, " \
               "ledrid #{demographics['ledrid'].inspect}"
          puts "Ppatient errors: #{ppatient.errors.to_a}"
          puts "Death_data errors: #{ppatient.death_data.errors.to_a}"
          puts "Death_data attributes: #{ppatient.death_data.attributes}"
          raise
        end
      else
        # Not in the database: we have to keep the entire batch in memory
        # Performance may be poor for large batches (> 4000 records)
        @batch.ppatients << ppatient
      end
      ppatient
    end

    # Returns an Array of field names including both direct and indirect indentifiers.
    def demographic_fields
      case @batch.e_type
      when 'PSDEATH'
        DIRECT_DEATH_IDENTIFIERS + INDIRECT_DEATH_IDENTIFIERS
      when 'PSBIRTH'
        DIRECT_BIRTH_IDENTIFIERS + INDIRECT_BIRTH_IDENTIFIERS
      else
        raise "Unknown demographics for e_type #{@batch.e_type}"
      end
    end

    # Should the rawtext of this source be preserved?
    def preserve_rawtext
      case @batch.e_type
      when 'PSDEATH', 'PSBIRTH'
        false
      else
        raise "Unknown e_type #{@batch.e_type}"
      end
    end


  end
end
