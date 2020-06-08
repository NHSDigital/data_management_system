#!/usr/bin/env ruby

# PostgreSQL doesn't allow ADDing columns to a table in a particular position -
# because it doesn't really make sense in SQL -
# but COPY from CSV **requires** the columns in a specific order
# as the fields aren't specified in the source CSV file.
# so specify /ALL/ of the fields to import.

require 'highline/import'
require 'csv'
require 'digest/sha1'
require 'base64'
require 'pg'
require 'date'
require 'yaml'

# ----------------------------------------------------------------------------------
def to_blob(b)
  # Convert raw binary data to a sequence of ASCII-encoded hex bytes,
  # suitable for import via COPY .. CSV into a PostgreSQL bytea field.
  '\\x' + (b.split('').map { |x| '%.2x' % x.ord }).join
end

# ----------------------------------------------------------------------------------
# Get year and month parameters from command line
if ARGV.size != 3
  puts "Usage: #{$PROGRAM_NAME} <year> <month> <part>"
  exit(1)
end
begin
  year = ARGV[0].to_i
  month = ARGV[1].to_i
  month2s = '%.2d' % [month]   # string version with leading 0 if needed
  part = ARGV[2]
  if part == 'a'
    partmatch = '01234567'
  elsif part == 'b'
    partmatch = '89abcdef'
  else
    fail
  end
rescue
  puts 'Parameter error'
  exit(1)
end

# Read database authentication parameters and data file path from yaml file,
# and create connection to database.
# yaml file:
#  database: <database>
#  username: <name>
#  password: <password>
#  csvpath: /dirpath/to/prescription_data
begin
  config = YAML.load_file('prescdb.yml')
  auth = { dbname:config['database'], user:config['username'], password:config['password'] }
  conn = PG.connect(auth)
rescue PG::Error => err
  puts err
  exit(1)
end

# Initialise empty cache for rawdata records - refreshed on per-month basis.
#  key = (rawdata,decrypt_key) [i.e. (encrypted_demog,key_bundle)]
#  value = ppatient_rawdataid
rawdata_cache = {}
rawdata_cache_size = 0
max_rawdata_cache_size = 30E6

# get last of: ppatients(id), ppatient_rawdata(ppatient_rawdataid), e_batch(e_batchid)
r = conn.exec('SELECT MAX(id) FROM ppatients')
last_ppatients_id = r.getvalue(0, 0).to_i    # return 0 if nil (no rows)
r = conn.exec('SELECT MAX(ppatient_rawdataid) FROM ppatient_rawdata')
last_ppatient_rawdataid = r.getvalue(0, 0).to_i
r = conn.exec('SELECT MAX(e_batchid) FROM e_batch')
last_e_batchid = r.getvalue(0, 0).to_i
conn.close

puts "Last: ppatients(id) = #{last_ppatients_id},"\
"rawdataid = #{last_ppatient_rawdataid},"\
"e_batchid = #{last_e_batchid}"
exit(0)

# ----------------------------------------------------------------------------------
# Use the last e_batchid value+1 from the e_batch table - this is the value for this month's load.
e_batchid = last_e_batchid
# Increment in part a only.
e_batchid += 1 if part == 'a'

ppatients_f = File.new("ppatients_#{year}#{month2s}#{part}.csv", 'w')
ppatient_rawdata_f = File.new("ppatient_rawdata_#{year}#{month2s}#{part}.csv", 'w')
prescription_data_f = File.new("prescription_data_#{year}#{month2s}#{part}.csv", 'w')

csvpath = config['csvpath']
csv_filename = File.join(csvpath, 'PHE_%d%s_pseudonymised.csv' % [year, month2s])
unless File.exists?(csv_filename)
  puts "#{csv_filename} doesn't exist."
  exit(1)
end

pseudonymisation_keyid = 1 # Hard-coded for PSPRESCRIPTION data
rown = 0
CSV.foreach(csv_filename) do |row|
  # first N data rows, skipping 2 header rows
  rown += 1
  next if rown <= 2

  data = row[0].split
  pseudo_id1 = data[0]
  # first character must match corresponding string for part a or b
  # so either [0-7] or [8-f] is matched.
  next unless partmatch.include?(pseudo_id1[0])

  key_bundle = Base64.decode64(data[1][1..-2])   # strip () before decoding
  encrypted_demog = Base64.decode64(data[2])

  rawdata_key = Digest::SHA1.digest(encrypted_demog + key_bundle)   # binary digest

  if rawdata_cache.key?(rawdata_key)
    rawdataid = rawdata_cache[rawdata_key]
    # puts "row #{rown}: using rawdata_cache: #{rawdataid}"
  else
    last_ppatient_rawdataid += 1
    rawdataid = last_ppatient_rawdataid
    # puts "row #{rown}: not cached, using: #{rawdataid}"

    # rawdata bytea,decrypt_key bytea
    # COPY ppatient_rawdata (rawdata,decrypt_key)
    # FROM 'input.csv' CSV;
    ppatient_rawdata_f.puts '"%s","%s"' % [to_blob(encrypted_demog),to_blob(key_bundle)]

    # Update cache, or reset if limit reached.
    # Each SHA1'ed key entry uses 160 bits = 20 bytes.
    # So 10 million entries ~= 200Mb.
    rawdata_cache_size += 1
    if rawdata_cache_size > max_rawdata_cache_size
      rawdata_cache = {}
      rawdata_cache_size = 0
    end
    rawdata_cache[rawdata_key] = rawdataid
  end

  # -- don't COPY id field and don't return it - use a counter here
  # COPY ppatients (e_batchid,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2,pseudonymisation_keyid)
  # FROM 'input.csv' CSV;
  ppatients_f.puts '%d,%d,"Pseudo::Prescription","%s",,%d' % [e_batchid, rawdataid, pseudo_id1, pseudonymisation_keyid]
  last_ppatients_id += 1

  # Fill in 5 deleted columns, removed in 2018-07 and later extracts:
  # PCO_NAME PRACTICE_NAME PRESC_QUANTITY CHEMICAL_SUBSTANCE_BNF CHEMICAL_SUBSTANCE_BNF_DESCR
  # Change row to row[0:5] + ['pco_name'] + row[5:6] + ['practice_name'] + row[6:7] + ['presc_quantity'] + row[7:21] + ['chemical_substance_bnf', 'chemical_substance_bnf_descr'] + row[21:]
  if row.size == 24
    row = row[0..4] + [''] + row[5..5] + [''] + row[6..6] + [''] + row[7..20] + ['', ''] + row[21..-1]
  end

  # prescription data -
  # basic data cleaning based on errors from PostgreSQL's COPY importer
  # - note that "" fields are already implicitly converted to <blank> from csv.reader
  # i.e. acceptable for COPY (e.g. for pat_age: integer field)
  if row[12].include?('.')
    # must be integer pay_quantity - round down
    row[12] = row[12].to_f.to_i
  end

  unless row.size == 29
    # Add additional dummy columns for PF_ID,AMPP_ID,VMPP_ID (not included in first 4 months' data)
    row += ['', '', ''] if row.size == 19

    # add additional dummy columns for SEX,FORM_TYPE,CHEMICAL_SUBSTANCE_BNF,
    # CHEMICAL_SUBSTANCE_BNF_DESCR,VMP_ID,VMP_NAME,VTM_NAME (not included in first 11 months' data,
    # but included in 2018-07 refresh)
    row += ['', '', '', '', '', '', ''] if row.size == 22

    raise 'Invalid row length: expected 28 fields of data'
  end

  # quote text fields, i.e. not integer
  ((0..28).to_a - [10,15,19,20,21,26]).each do |f|
    row[f] = '"%s"' % row[f]
  end

  # remove demog - leave till last to avoid index confusion
  row.delete_at(0)

  # remove quotes from PRESC_DATE field (DATE type) - a blank field will be stored as NULL.
  row[0] = row[0].delete('"')

  # COPY prescription_data
  # (ppatient_id,presc_date,part_month,presc_postcode,pco_code,pco_name,practice_code,practice_name,
  #  nic,presc_quantity,item_number,unit_of_measure,pay_quantity,drug_paid,bnf_code,
  #  pat_age,pf_exempt_cat,etp_exempt_cat,etp_indicator,pf_id,ampp_id,vmpp_id,
  #  sex,form_type,chemical_substance_bnf,chemical_substance_bnf_descr,vmp_id,vmp_name,vtm_name)
  # FROM 'input.csv' CSV;
  prescription_data_f.puts((['%d' % last_ppatients_id] + row).to_csv)
  # prescription_data_f.puts(['%d' % last_ppatients_id] + row).join(',')

  if (rown % 1000) == 0
    # memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
    # print "\r#{rown}: #{last_ppatients_id}, #{last_ppatient_rawdataid} [#{memory_usage}Kb]"
    print "\r#{rown}: #{last_ppatients_id}, #{last_ppatient_rawdataid}"
  end

end    # end of row loop
puts

ppatients_f.close
ppatient_rawdata_f.close
prescription_data_f.close

# Part a only - create an e_batch record for this month
if part == 'a'
  e_batch_f = File.new("e_batch_#{year}_#{month2s}.csv", 'w')

  # COPY e_batch
  # (e_type,provider,media,original_filename,cleaned_filename,numberofrecords,
  #  date_reference1,date_reference2,e_batchid_traced,comments,digest,
  #  lock_version,inprogress,registryid,on_hold)
  monthend = Date.civil(year, month, -1).day
  dateref1 = '%d-%.2d-01' % [year, month]
  dateref2 = '%d-%.2d-%.2d' % [year, month, monthend]
  num_rows = rown - 3   # 2 header rows from 0
  filename = File.basename(csv_filename)

  e_batch_f.puts \
    %("PSPRESCRIPTION","T145Z","Hard Disk","%s","%s",%d,%s,%s,0,"Month %d batch","Not computed",0,"","X25",0) \
    % [filename, filename, num_rows, dateref1, dateref2, month]

  e_batch_f.close
end

puts "\nFinal cache size = #{rawdata_cache.length}"
