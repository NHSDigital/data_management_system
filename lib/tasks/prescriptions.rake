require 'ndr_import/file/delimited'
require 'highline/import'
require 'csv'
require 'digest'
require 'base64'
require 'pg'


# ------------------------------------------------------------------------
namespace :prescription do
  desc 'Look at database'
  task look: :environment do
    puts 'Ppatients:'
    Pseudo::Ppatient.all.each do |p|
      puts p.to_yaml
    end
    puts 'Prescriptions:'
    Pseudo::Prescription.all.each do |p|
      puts p.to_yaml
    end
  end

  # ----------------------------------------------
  def compute_digest(csv_file)
    # KH: realistically it will take too long (>10 minutes) to SHA1 hash a ~33Gb text file.
    digest = 'not computed'
    # digest = Digest::SHA1.new
    # numrecords = 0
    # open(csv_file, 'r').each do |l|
      # digest << l
      # numrecords += 1
    # end
    # digest.hex
    digest
  end

  # ----------------------------------------------
  class PatientRecord
    attr_reader :rawdata_cache
    attr_reader :conn

    def initialize(db)
      # type of database access:
      # 'AR' = ActiveRecord
      # 'PG' = PostgreSQL API (ruby-pg)
      # 'SQL' = native PostgreSQL commands
      @db = db
      if db == 'PG'
        c = Rails.application.config.database_configuration[Rails.env]
        begin
          @conn = PG.connect(dbname: c['database'], user: c['username'], password: c['password'], host: c['host'])
        rescue PG::Error => err
          puts 'In PatientRecord::initialize:'
          puts err
          exit(1)
        end
      elsif db != 'AR'
        puts 'Not implemented yet'
        exit(1)
      end
      # cache rawdata
      @rawdata_cache = {}
    end

    def reset_prescriptions
      # this method is intended for testing only.
      if @db == 'AR'
        Pseudo::Ppatient.delete_all
        Pseudo::PpatientRawdata.delete_all
        Pseudo::PrescriptionData.delete_all
        EBatch.delete_all
        ZeType.delete_all
        Zprovider.delete_all
        ZeType.create!(ze_typeid: 'PSPRESCRIPTION')
        # **** Records must be created for both provider and registry. ****
        # **** They are both created as zproviderid in Zprovider.      ****
        Zprovider.create!(zproviderid: 'T145Z')
        Zprovider.create!(zproviderid: 'X25')

        # Reset primary keys
        ActiveRecord::Base.connection.reset_pk_sequence!('ppatients')
        ActiveRecord::Base.connection.reset_pk_sequence!('ppatient_rawdata')
        ActiveRecord::Base.connection.reset_pk_sequence!('prescription_data')
      elsif @db == 'PG'
        begin
          # TRUNCATE is a PostgreSQL extension which is quicker than DELETE FROMs.
          # Corresponding (inherited from ppatients) prescription_data rows are also deleted.
          @conn.exec('TRUNCATE ppatients,ppatient_rawdata,e_batch,ze_type,zprovider CASCADE')

          # Reset primary keys
          @conn.exec('ALTER SEQUENCE ppatients_id_seq RESTART WITH 1')
          @conn.exec('ALTER SEQUENCE ppatient_rawdata_ppatient_rawdataid_seq RESTART WITH 1')
          @conn.exec('ALTER SEQUENCE prescription_data_prescription_dataid_seq RESTART WITH 1')

          @conn.exec('INSERT INTO ze_type VALUES ($1::text)', ['PSPRESCRIPTION'])
          @conn.exec('INSERT INTO zprovider (zproviderid) VALUES ($1::text),($2::text)',
                        ['T145Z','X25'])
        rescue PG::Error => err
          puts 'In PatientRecord::reset_prescriptions:'
          puts err
          exit(1)
        end
      else
        puts 'Not implemented yet'
        exit(1)
      end
    end

    def insert(row, encrypted_demog, key_bundle, pseudo_id1, e_batchid)
      pseudonymisation_keyid = 1 # Hard-coded for PSPRESCRIPTION data
      # check if rawdata has already been stored
      rawdata = [encrypted_demog, key_bundle]
      if @rawdata_cache.key?(rawdata)
        already_cached = true
        rawdataid,patid = @rawdata_cache[rawdata]
      else
        already_cached = false
        # create new ppatient_rawdata record and add ids to cache
        if @db == 'PG'
          begin
            q = <<-SQL
            INSERT INTO ppatient_rawdata
            VALUES (DEFAULT, $1, $2)
            RETURNING ppatient_rawdataid
            SQL
            result = @conn.exec_params(
              q,
              [to_blob(encrypted_demog), to_blob(key_bundle)]
            )
            rawdataid = result[0]['ppatient_rawdataid']
          rescue PG::Error => err
            puts 'In PatientRecord::insert (ppatient_rawdata)'
            puts err
            exit(1)
          end
        elsif @db == 'AR'
          rawdata_record = Pseudo::PpatientRawdata.create(
            rawdata: encrypted_demog,
            decrypt_key: key_bundle
          )
          rawdataid = rawdata_record.ppatient_rawdataid
        end

        # also add new ppatients record
        if @db == 'PG'
          begin
            q = <<-SQL
            INSERT INTO ppatients
            VALUES (DEFAULT, $1::int, $2::int, 'Pseudo::Prescription', $3::text, NULL, $4::int)
            RETURNING id
            SQL
            result = @conn.exec_params(q,
                                       [e_batchid, rawdataid, pseudo_id1, pseudonymisation_keyid])
            patid = result[0]['id']
          rescue PG::Error => err
            puts 'In PatientRecord::insert (ppatients)'
            puts err
            exit(1)
          end
        elsif @db == 'AR'
          pat = Pseudo::Ppatient.create(
            e_batch_id: e_batchid,
            ppatient_rawdata_id: rawdataid,
            type: 'Pseudo::Prescription',
            pseudo_id1: pseudo_id1,
            # No date of birth + postcode for prescription data
            pseudo_id2: nil,
            pseudonymisation_keyid: pseudonymisation_keyid
          )
          patid = pat.id
        end

        # update cache
        @rawdata_cache[rawdata] = [rawdataid,patid]
      end   # store records

      fields = row.except('demog', 'presc_date', :rawtext)

      if @db == 'AR'
        if already_cached
          pr = Pseudo::PrescriptionData.new(fields)
          pr.ppatient_id = patid
          pr.save!
        else
          pr = pat.prescription_data.build(fields)
          pr.save!
          pat.save!
          rawdata_record.save!
        end
      elsif @db == 'PG'
        # ruby-pg doesn't allow a literal empty string as input for an integer field
        fields['pat_age'] = nil if fields['pat_age']==''
        fields['pf_id'] = nil if fields['pf_id']==''
        fields['ampp_id'] = nil if fields['ampp_id']==''
        fields['vmpp_id'] = nil if fields['vmpp_id']==''
        fields['vmp_id'] = nil if fields['vmp_id']==''
        # For an integer field, ActiveRecord truncates a float input,
        # but ruby-pg rounds it up.
        begin
          fields['pay_quantity'] = fields['pay_quantity'].to_f.to_i
        rescue
          puts fields
          exit(1)
        end
        begin
          # concatenate $1,$2,.. etc. up to number of fields
          params = (1..fields.size+1).collect {|e| "$#{e}"}.join(",")
           q = <<-SQL
          INSERT INTO prescription_data
          VALUES (DEFAULT, #{params})
          SQL
          # Fields are stored in the database order,
          # and Ruby will retrieve the values in the same order -
          # but patid must be added separately rather than allocated
          # in the hash to preserve this order.
          @conn.exec_params(q, [patid]+fields.values)
        rescue PG::Error => err
          puts 'In PatientRecord::insert (prescription_data)'
          puts err
          puts fields
          puts fields.size
          exit(1)
        end
      end
    end

    private

    # Convert a binary string (output from Base64::decode)
    # into a hex representation suitable for PostgreSQL's bytea hex field.
    def to_blob(s)
      '\x'+s.unpack('H*')[0]
    end
  end

  # ----------------------------------------------
  desc 'Manage pseudonymised prescription data'
  task import_pseudonymised: :environment do |taskname|
    csv_fname = ENV['infile']
    begin
      csv_file = SafePath.new('prescr_data').join(csv_fname)
    rescue
      puts "Can't find CSV file #{csv_fname} using SafePath."
      puts "- check filesystem_paths.yml"
      exit(1)
    end
    puts "#{csv_file} doesn't exist." unless SafeFile.exist?(csv_file)

    digest = compute_digest(csv_file)

    # set database access method here
    pat = PatientRecord.new('AR')
    pat.reset_prescriptions

    # create EBatch record
    ebatch = EBatch.create!(
      e_type: 'PSPRESCRIPTION',
      provider: 'T145Z',
      media: 'disk',
      original_filename: csv_fname,
      cleaned_filename: csv_fname,
      numberofrecords: 0,
      date_reference1: '2015.04.01',  # year/month (here 2015.04) to be entered by user, presumably
      date_reference2: '2015.04.30',
      e_batchid_traced: nil,          # KH: unknown
      comments: 'month 4 batch',      # manual entry again
      digest: digest,
      lock_version: 0,                # KH: unknown
      inprogress: '',                 # KH: unknown
      registryid: 'X25',
      on_hold: 0                      # KH: unknown
    )

    mappings_file = Rails.root.join('lib/tasks/prescription_mappings.yml')

    mappings = YAML.load_file(mappings_file)
    table = NdrImport::Table.new(mappings)

    # For each pseudonymised row, create a corresponding Prescription row,
    # and link rawdata appropriately
    # (converting base64 data to raw binary data), re-using identical PpatientRawData (type Prescription) rows
    # for the same provider wherever possible, and also a row in a new Prescription table
    # to hold the prescription data items.

    # pseudo_id1 [always hex], key_bundle [base-64 encoded], encrypted_demographics [base-64 encoded]
    # where key_bundle is the demog_key encrypted with (real_id1 + salt_demog).
    # store in db:
    #   pseudo_id1 (as hex)
    #   key_bundle (decode base-64, store as binary data)
    #   encrypted_demographics (decode base-64, store as binary data)

    # there is actually only one file here
    tables = NdrImport::File::Registry.tables(csv_file, nil, {})
    tables.each do |_tablename, table_content|
      # read one line at a time
      @rown = 0
      table.transform(table_content).each do |_klass, _row, _index|
        # We need to use the :rawtext key here, as ndr_import silently removes
        # fields that are blank, i.e. ,, or ,"", (both are valid: RCF4180 section 2.5)
        # This behaviour doesn't appear to be documented.
        row = _row[:rawtext]

        data = row['demog'].split
        pseudo_id1 = data[0]
        key_bundle = Base64.decode64(data[1][1..-2])   # strip () before decoding
        encrypted_demog = Base64.decode64(data[2])

        pat.insert(row, encrypted_demog, key_bundle, pseudo_id1, ebatch.e_batchid)

        @rown += 1
        print "\rImported record: #{@rown}"
      end
    end

    puts
    puts "rawdata cache size = #{pat.rawdata_cache.size}"

    ebatch.numberofrecords = @rown
    ebatch.save!
  end  # task

  # ------------------------------------------------------------------------
  # Manage pseudonymisation keys
  namespace :keys do
    desc 'List pseudonymisation keys'
    task list: :environment do |taskname|
      puts Pseudo::PseudonymisationKey.all.to_yaml
      if Pseudo::PseudonymisationKey.all.empty?
        puts 'No pseudonymisation keys.'
      else
        PseudonymisationKey.all.each { |pkey| puts pkey }
      end
    end

    desc 'Manage pseudonymisation keys'
    task manage: :environment do |taskname|
      begin
        salt_file = ENV['salt_file']
        puts salt_file
        raise unless File.exist?(salt_file)
      rescue
        puts 'Can\'t open salt file.'
        exit(1)
      end

      salt = nil
      3.times do
        begin
          salt_pass = ask('Please enter your salt bundle password, and press Enter: ') do |q|
            q.echo = false
          end
          salt = NdrPseudonymise::PseudonymisationSpecification.get_key_bundle(
            salt_file,
            salt_pass
          )
          break
        rescue => e
          puts "Error: #{e.message}"
        end
      end
      if salt.nil?
        puts 'Error: Cannot load salt bundle: aborting'
        exit(1)
      end

      [:salt1, :salt2].each do |x|
        if salt[x].to_s.size < 64
          puts "Error: Invalid salt #{x.inspect} in salt file #{salt_file}"
          exit(1)
        end
      end
    end
  end
end
