#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: $(basename $0) <year> <month> <part>"
  exit 0
fi
year="$1"
month=$(printf "%.2d" "$2")
[ $month == "00" ] && exit 1  # error from printf
part="$3"
[ $part == "a" -o $part == "b" ] || exit 1   # part must a or b

if [ -z "$DB" -o -z "$DBA" ] ; then
  echo Error: expected environment variables DB and DBA to be defined
  exit 1
fi
# TODO: Pipe data from stdin, to avoid having to run script on db server
CSVDIR="/home/pgsql_recovery/source_data/loading"

echo "COPYing $year,$month,$part"

if [ $part == "a" ]; then
psql -q $DB -U $DBA <<SQL
BEGIN;
COPY e_batch (e_type,provider,media,original_filename,cleaned_filename,numberofrecords,
date_reference1,date_reference2,e_batchid_traced,comments,digest,
lock_version,inprogress,registryid,on_hold)
FROM '$CSVDIR/e_batch_${year}${month}.csv' CSV;
COMMIT;
SQL
fi

psql -q $DB -U $DBA <<SQL
BEGIN;
COPY ppatient_rawdata (rawdata,decrypt_key)
FROM '$CSVDIR/ppatient_rawdata_${year}${month}${part}.csv' CSV;
COPY ppatients (e_batch_id,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2,pseudonymisation_keyid)
FROM '$CSVDIR/ppatients_${year}${month}${part}.csv' CSV;
COPY prescription_data (ppatient_id,presc_date,part_month,presc_postcode,pco_code,pco_name,
practice_code,practice_name,nic,presc_quantity,item_number,
unit_of_measure,pay_quantity,drug_paid,bnf_code,pat_age,
pf_exempt_cat,etp_exempt_cat,etp_indicator,pf_id,ampp_id,vmpp_id,
sex,form_type,chemical_substance_bnf,chemical_substance_bnf_descr,vmp_id,vmp_name,vtm_name)
FROM '$CSVDIR/prescription_data_${year}${month}${part}.csv' CSV;
COMMIT;
SQL

