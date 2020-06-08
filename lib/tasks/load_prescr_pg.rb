#!/usr/bin/env ruby

# Minimal prescription data importer using ruby-pg
# Standalone version (without Rails and ndr_import gems)

require 'highline/import'
require 'csv'
require 'digest'
require 'base64'
require 'pg'

# ----------------------------------------------
def pg_compute_digest(csv_file)
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
class PG_PatientRecord
  attr_reader :rawdata_cache
  attr_reader :conn

  def initialize(auth)
    begin
      @conn = PG.connect(auth)
    rescue PG::Error => err
      puts 'In PatientRecord::initialize:'
      puts err
      exit(1)
    end
    # cache rawdata
    @rawdata_cache = {}
  end

  def reset_prescriptions
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
  end

  def insert(row, encrypted_demog, key_bundle, pseudo_id1, e_batchid)
    # check if rawdata has already been stored
    rawdata = [encrypted_demog, key_bundle]
    if @rawdata_cache.key?(rawdata)
      already_cached = true
      rawdataid = @rawdata_cache[rawdata]
    else
      already_cached = false
      # create new ppatient_rawdata record and add to cache
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

      # update cache
      @rawdata_cache[rawdata] = rawdataid
    end

    # add new ppatients record
    begin
      q = <<-SQL
      INSERT INTO ppatients
      VALUES (DEFAULT, $1::int, $2::int, 'Pseudo::Prescription', $3::text, NULL)
      RETURNING id
      SQL
      result = @conn.exec_params(q, [e_batchid, rawdataid, pseudo_id1])
      patid = result[0]['id']
    rescue PG::Error => err
      puts 'In PatientRecord::insert (ppatients)'
      puts err
      exit(1)
    end

    fields = row
    fields.delete('demog')
    fields.delete('presc_date')

    # ruby-pg doesn't allow a literal empty string as input for an integer field
    fields['pat_age'] = nil if fields['pat_age']==''
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
      params = (1..fields.values.size+1).collect {|e| "$#{e}"}.join(",")
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

  private

  # Convert a binary string (output from Base64::decode)
  # into a hex representation suitable for PostgreSQL's bytea hex field.
  def to_blob(s)
    '\x'+s.unpack('H*')[0]
  end
end

# ----------------------------------------------
if ARGV.size!=1
  puts "Usage: #{$0} <CSV file>"
  exit(1)
end

csv_file = ARGV[0]
unless File.exist?(csv_file)
  puts "#{csv_file} doesn't exist."
  exit(1)
end
csv_fname = File.basename(csv_file)

digest = pg_compute_digest(csv_file)

password = ask('DB password: ') {|a| a.echo = false}
auth = {dbname:'some_database',user:'some_user',host: 'some_host',password: password}

pat = PG_PatientRecord.new(auth)
pat.reset_prescriptions

# create EBatch record
begin
  q = <<-SQL
  INSERT INTO e_batch
  VALUES (DEFAULT,'PSPRESCRIPTION','T145Z','disk',
  $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
  RETURNING e_batchid
  SQL
  result = pat.conn.exec_params(q,
    [csv_fname, csv_fname, 0,
    # year/month (here 2015.04) to be entered by user, presumably
    '2015.04.01', '2015.04.30',
    nil,  # e_batchid_traced: unknown
    'month 4 batch',   # manual entry for comments
    digest,
    0,    # lock_version: unknown
    '',   # inprogress: unknown
    'X25',  # registryid
    0    # on_hold: unknown
    ])
    e_batchid = result[0]['e_batchid']
rescue PG::Error => err
  puts 'create EBatch record:'
  puts err
  exit(1)
end

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

# These names are taken from the /slightly edited/ version of the transferred CSV files
# - that is, with the first "header row" removed
# and the first 3 header labels collapsed to 1.
# Using native CSV it will be possible to read them without prior editing.
field_names = %w(demog presc_date part_month presc_postcode pco_code pco_name practice_code practice_name nic presc_quantity item_number unit_of_measure pay_quantity drug_paid bnf_code pat_age pf_exempt_cat etp_exempt_cat etp_indicator)

header_rows = 2
pat.conn.transaction do |tr|
  # read one line at a time
  @rown = 0
  CSV.foreach(csv_file) do |csvrow|
    @rown += 1
    next if @rown<=header_rows
    row = Hash[field_names.zip(csvrow)]

    data = row['demog'].split
    pseudo_id1 = data[0]
    key_bundle = Base64.decode64(data[1][1..-2])   # strip () before decoding
    encrypted_demog = Base64.decode64(data[2])

    pat.insert(row, encrypted_demog, key_bundle, pseudo_id1, e_batchid)

    print "\rImported record: #{@rown-header_rows}"
  end
end  # transaction

puts
puts "rawdata cache size = #{pat.rawdata_cache.size}"

begin
  q = 'UPDATE e_batch SET numberofrecords=$1 WHERE e_batchid=$2'
  result = pat.conn.exec_params(q, [@rown-header_rows, e_batchid])
rescue PG::Error => err
  puts 'update EBatch record:'
  puts err
  exit(1)
end
