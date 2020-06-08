#!/usr/bin/env python

# PostgreSQL doesn't allow ADDing columns to a table in a particular position -
# because it doesn't really make sense in SQL -
# but COPY from CSV **requires** the columns in a specific order
# as the fields aren't specified in the source CSV file.
# so specify /ALL/ of the fields to import.

# This code assumes a database with exclusive access to EBatch / Ppatient /
# PpatientRawdata tables, where the latest values from each sequence have been
# committed as entries in the database. It works by trying to precompute the
# next values that will come off each sequence, then doing a direct load of
# the data as a CSV file.
# If the database state doesn't support this, you could workaround with:
#   ./fix_prescr_sequences.sh
# Old workaround:
#   irb> eb=EBatch.new; eb.save(validate: false)
#   irb> pprd=Pseudo::PpatientRawdata.new; pprd.save(validate:false)
#   irb> pp=Pseudo::Ppatient.new; pp.save(validate:false)
#   $ ./create_prescr.py 2015 04 a
#   $ ./load_tables.sh 2015 04 a
#   irb> eb.destroy; pprd.destroy; pp.destroy
# We could make this work slightly more expensively but more reliably, by actually
# pulling a single value off each sequence below.

# use Python 3 print
from __future__ import print_function

import sys
import calendar
import psycopg2
import csv
import base64
import hashlib
import getpass
import os.path
import os

# ----------------------------------------------------------------------------------
def to_asciihex(b):
  """
  Convert raw binary data to a sequence of ASCII-encoded hex bytes,
  suitable for import via COPY .. CSV into a PostgreSQL bytea field.
  """
  return '\\x'+''.join('%.2x' % ord(x) for x in b)


# ----------------------------------------------------------------------------------
# Get year and month parameters from command line
if len(sys.argv)!=4:
  print('Usage: %s <year> <month> <part>' % sys.argv[0])
  print("""  where <part> is a or b - meaning choose rows with
  pseudo_id1 starting with 0-7 (a) or 8-f (b).
  This is to split the CSV file into two equal (manageable) chunks
  due to limited memory on the db1 server""")
  exit(1)

try:
  year = int(sys.argv[1])
  month = int(sys.argv[2])
  month2s = '%.2d' % month   # string version with leading 0 if needed
  part = sys.argv[3]
  if part=='a':
    partmatch = '01234567'
  elif part=='b':
    partmatch = '89abcdef'
  else:
    raise     # part must be a or b
except:
  print('Parameter error')
  sys.exit(1)

DB=os.environ['DB']
DBA=os.environ['DBA']
csvpath = '/home/pgsql_recovery/source_data/static'

# Initialise empty cache for rawdata records - refreshed on per-month basis.
#  key = (rawdata,decrypt_key) [i.e. (encrypted_demog,key_bundle)]
#  value = ppatient_rawdataid
rawdata_cache = {}
rawdata_cache_size = 0
max_rawdata_cache_size = 30E6

password = os.environ.get('PGPASSWORD') or getpass.getpass('(create_prescr.py) DB password: ')
conn = psycopg2.connect('dbname=%s user=%s password=%s' % (DB,DBA,password))
cur = conn.cursor()

# get last of: ppatients(id), ppatient_rawdata(ppatient_rawdataid), e_batch(e_batchid)
cur.execute('SELECT MAX(id) FROM ppatients')
last_ppatients_id = cur.fetchone()[0] or 0    # return 0 if None (no rows)
cur.execute('SELECT MAX(ppatient_rawdataid) FROM ppatient_rawdata')
last_ppatient_rawdataid = cur.fetchone()[0] or 0
cur.execute('SELECT MAX(e_batchid) FROM e_batch')
last_e_batchid = cur.fetchone()[0] or 0

print('Last: ppatients(id) = %d, rawdataid = %d, e_batchid = %d' % (last_ppatients_id,last_ppatient_rawdataid,last_e_batchid))

# ----------------------------------------------------------------------------------
# Use the last e_batchid value from the e_batch table - this is the value for this month's load.
# Increment in part a only.
e_batchid = last_e_batchid
if part=='a':
  e_batchid += 1

ppatients_f = open('ppatients_%d%s%s.csv' % (year,month2s,part), 'a')
ppatients_f.truncate(0)
ppatient_rawdata_f = open('ppatient_rawdata_%d%s%s.csv' % (year,month2s,part), 'a')
ppatient_rawdata_f.truncate(0)
prescription_data_f = open('prescription_data_%d%s%s.csv' % (year,month2s,part), 'a')
prescription_data_f.truncate(0)

csv_filename = os.path.join(csvpath, 'PHE_%d%s_pseudonymised.csv' % (year,month2s))

with open(csv_filename, 'r') as csvfile:
  preader = csv.reader(csvfile, delimiter=',', quotechar='"')
  # prescription_data_writer = csv.writer(prescription_data_f)
  pseudonymisation_keyid = 1 # Hard-coded for PSPRESCRIPTION data
  # first N data rows, skipping 2 header rows
  rown = 0
  for row in preader:
    rown += 1
    if rown<=2: continue
    # if rown>=1000003: break # For testing: only load first 1,000,000 rows

    data = row[0].split()
    pseudo_id1 = data[0]
    if pseudo_id1[0] not in partmatch:
      # first character must match corresponding part
      continue

    key_bundle = to_asciihex(base64.b64decode(data[1][1:-1]))   # strip () before decoding
    encrypted_demog = to_asciihex(base64.b64decode(data[2]))

    # Binary digest = 20 bytes.
    # [Python] 20-byte string takes 52 bytes
    # 10-byte string takes 47 bytes.
    rawdata_key = hashlib.sha1(encrypted_demog+key_bundle).digest()

    if rawdata_key in rawdata_cache:
      rawdataid = rawdata_cache[rawdata_key]
      # print('row %d: using rawdata_cache: %d' % (rown,rawdataid))
    else:
      last_ppatient_rawdataid += 1
      rawdataid = last_ppatient_rawdataid
      #print('row %d: not cached, using: %d' % (rown,rawdataid))

      # rawdata bytea,decrypt_key bytea
      # COPY ppatient_rawdata (rawdata,decrypt_key)
      # FROM 'input.csv' CSV;
      print('"%s","%s"' % (encrypted_demog,key_bundle), file=ppatient_rawdata_f)

      # Update cache, or reset if limit reached.
      # Each SHA1'ed key entry uses 160 bits = 20 bytes, but the python object size is 52 bytes.
      # int takes 24 bytes, so total for hash entry is 79 bytes.
      # So 10 million entries ~= 790Mb.
      rawdata_cache_size += 1
      if rawdata_cache_size > max_rawdata_cache_size:
        print('Cache size limit (%d) reached - resetting cache.' % rawdata_cache_size)
        rawdata_cache = {}
        rawdata_cache_size = 0
      rawdata_cache[rawdata_key] = rawdataid

    # -- don't COPY id field and don't return it - use a counter here.
    # COPY ppatients (e_batchid,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2,pseudonymisation_keyid)
    # FROM 'input.csv' CSV;
    print('%d,%d,"Pseudo::Prescription","%s",,%d' % (e_batchid,rawdataid,pseudo_id1,pseudonymisation_keyid), file=ppatients_f)
    last_ppatients_id += 1

    # Fill in 5 deleted columns, removed in 2018-07 and later extracts:
    # PCO_NAME PRACTICE_NAME PRESC_QUANTITY CHEMICAL_SUBSTANCE_BNF CHEMICAL_SUBSTANCE_BNF_DESCR
    # Change row to row[0:5] + ['pco_name'] + row[5:6] + ['practice_name'] + row[6:7] + ['presc_quantity'] + row[7:21] + ['chemical_substance_bnf', 'chemical_substance_bnf_descr'] + row[21:]
    if len(row) == 24:
      row = row[0:5] + [''] + row[5:6] + [''] + row[6:7] + [''] + row[7:21] + ['', ''] + row[21:]

    # prescription data -
    # basic data cleaning based on errors from PostgreSQL's COPY importer
    # - note that "" fields are already implicitly converted to <blank> from csv.reader
    # i.e. acceptable for COPY (e.g. for pat_age: integer field)
    if '.' in row[12]:
       # must be integer pay_quantity - round down
       row[12] = int(float(row[12]))

    # Add additional dummy columns for PF_ID,AMPP_ID,VMPP_ID (not included in first 4 months' data)
    if len(row) == 19: row += ['', '', '']

    # add additional dummy columns for SEX,FORM_TYPE,CHEMICAL_SUBSTANCE_BNF,
    # CHEMICAL_SUBSTANCE_BNF_DESCR,VMP_ID,VMP_NAME,VTM_NAME (not included in first 11 months' data,
    # but included in 2018-07 refresh)
    if len(row) == 22: row += ['', '', '', '', '', '', '']

    # quote text fields, i.e. not integer
    # TODO: Move to using a proper CSV library instead of manual quoting
    for f in range(29):
       if f not in (10,15,19,20,21,26): # ITEM_NUMBER,PAT_AGE,PF_ID,AMPP_ID,VMPP_ID,VMP_ID
          row[f] = '"%s"' % row[f]

    # remove DEMOG field - leave till last to avoid index confusion
    del row[0]

    # remove quotes from PRESC_DATE field (DATE type) - a blank field will be stored as NULL.
    row[0] = row[0].replace('"','')

    # COPY prescription_data
    # (ppatient_id,presc_date,part_month,presc_postcode,pco_code,pco_name,practice_code,practice_name,
    #  nic,presc_quantity,item_number,unit_of_measure,pay_quantity,drug_paid,bnf_code,
    #  pat_age,pf_exempt_cat,etp_exempt_cat,etp_indicator,pf_id,ampp_id,vmpp_id,
    #  sex,form_type,chemical_substance_bnf,chemical_substance_bnf_descr,vmp_id,vmp_name,vtm_name)
    # FROM 'input.csv' CSV;
    print(','.join(['%d' % last_ppatients_id] + row), file=prescription_data_f)
    # prescription_data_writer.writerow(['%d' % last_ppatients_id] + row)

    if (rown%1000)==0:
      sys.stdout.write('%d: %d, %d\r' % (rown,last_ppatients_id,last_ppatient_rawdataid))
      sys.stdout.flush

    # end of row loop

ppatients_f.close()
ppatient_rawdata_f.close()
prescription_data_f.close()

# Part a only - create an e_batch record for this month
if part=='a':
  e_batch_f = open('e_batch_%d%s.csv' % (year,month2s), 'w')

  # COPY e_batch
  # (e_type,provider,media,original_filename,cleaned_filename,numberofrecords,
  #  date_reference1,date_reference2,e_batchid_traced,comments,digest,
  #  lock_version,inprogress,registryid,on_hold)
  month = int(month)
  monthend = calendar.monthrange(year,month)[1]
  dateref1 = '%d-%.2d-01' % (year,month)
  dateref2 = '%d-%.2d-%.2d' % (year,month,monthend)
  num_rows = rown-3   # 2 header rows from 0
  filename = os.path.basename(csv_filename)
  print(\
  """"PSPRESCRIPTION","T145Z","Hard Disk","%s","%s",%d,%s,%s,0,"Month %d batch","Not computed",0,"","X25",0""" \
  % (filename,filename,num_rows,dateref1,dateref2,month), file=e_batch_f)
  e_batch_f.close()


print('\nFinal cache size = %d' % (len(rawdata_cache)))

# ----------------------------------------------------------------------------------


"""
DEMOG,PRESC_DATE,PART_MONTH,PRESC_POSTCODE,PCO_CODE,PCO_NAME,PRACTICE_CODE,PRACTICE_NAME,NIC,PRESC_QUANTITY,ITEM_NUMBER,UNIT_OF_MEASURE,PAY_QUANTITY,DRUG_PAID,BNF_CODE,PAT_AGE,PF_EXEMPT_CAT,ETP_EXEMPT_CAT,ETP_INDICATOR

0    pseudoid text,
1    presc_date text,
2    part_month text,
3    presc_postcode text,
4    pco_code text,
5    pco_name text,
6    practice_code text,
7    practice_name text,
8    nic text,
9    presc_quantity text,
10   item_number integer,
11   unit_of_measure text,
12   pay_quantity integer,
13   drug_paid text,
14   bnf_code text,
15   pat_age integer,
16   pf_exempt_cat text,
17   etp_exempt_cat text,
18   etp_indicator text

# e_batchid         | 1       -- autoincrement primary key
# e_type            | PSPRESCRIPTION
# provider          | T145Z
# media             | Hard Disk    -- options in era are: 'Email', 'Floppy Disk', 'CD/DVD', 'Others'
# original_filename | PHE_201504_pseudonymised_first10000.csv
# cleaned_filename  | PHE_201504_pseudonymised_first10000.csv
# numberofrecords   | 10000
# date_reference1   | 2015-04-01 00:00:00  -- beginning of month
# date_reference2   | 2015-04-30 00:00:00  -- end of month
# e_batchid_traced  |
# comments          | month 4 batch
# digest            | not computed
# lock_version      | 0
# inprogress        |
# registryid        | X25
# on_hold           | 0
"""
