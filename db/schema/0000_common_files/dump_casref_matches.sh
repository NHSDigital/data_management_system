#!/bin/bash

# dump tables for matched CASREF patients, for loading into CASREF (Oracle db).
# - on testdb:
#  20m31.114s
#
#   4920282 public.ppatients.out
#   4706373 public.prescription_data.out

# Database containing the prescription data
# DBNAME='-h ncr-prescr-db1 testdb'
DBNAME='testdb'

# Export PGUSER and PGPASSWORD to make this run automatically in a script
if [ -z "$PGUSER" ]; then
  read -rp 'Enter DBA, e.g. dbakelvinhunter: ' PGUSER
  export PGUSER
fi
if [ -z "$PGPASSWORD" ]; then
  read -p 'Enter PGPASSWORD: ' -rs PGPASSWORD
  echo
  export PGPASSWORD
fi

if [ -z "$REPSEUDOSALT"]; then
  read -p 'Enter REPSEUDOSALT [leave blank to not repseudonymise]: ' -rs REPSEUDOSALT
  echo
  if ! echo "$REPSEUDOSALT" | egrep -q '^([0-9a-f]{64})?$' ; then
    echo Error: Invalid REPSEUDOSALT: Expected blank or 64 hex characters
    exit 1
  fi
  export REPSEUDOSALT
fi

psql $DBNAME -c "\dt prescription_patientids*"
read -rp "Enter linkage table to use (e.g. prescription_patientids_amr1902): " link_table

echo 'TODO: Check linkage table has unique pseudo_id1 values, or create a driver table'

# Identify records to extract
q="select e_batchid, provider, original_filename, cleaned_filename
   from e_batch where e_type='PSPRESCRIPTION' order by e_batchid"
psql $DBNAME -c "$q"

read -p "Enter min_e_batchid to extract: " min_e_batchid
read -p "Enter max_e_batchid to extract: " max_e_batchid

q="select min(id) as min_ppatientid, max(id) as max_ppatientid
   from ppatients left join e_batch on ppatients.e_batch_id = e_batch.e_batchid
   where e_type='PSPRESCRIPTION' and e_batch_id between ${min_e_batchid} and ${max_e_batchid}"
psql $DBNAME -c "\copy ($q) to 'ppatientid_range.csv' CSV HEADER"

min_ppatientid=`tail -n+2 ppatientid_range.csv |cut -d, -f1`
max_ppatientid=`tail -n+2 ppatientid_range.csv |cut -d, -f2`


# e_batch extract
q="SELECT e_batch.* FROM e_batch
   WHERE e_batchid between ${min_e_batchid} and ${max_e_batchid}
   ORDER by e_batchid"
#psql $DBNAME -t -A -F $'\037' -R $'\036\012' -c "$q" \
#  | sed '$ s/\(.\)$/\1\o36/' >public.e_batch_all.out
psql $DBNAME -c "\copy ($q) TO 'public.e_batch_all.csv' CSV HEADER"

# linked prescription_data extract
q="SELECT prescription_data.* FROM prescription_data
   JOIN ppatients ON ppatients.id=prescription_data.ppatient_id
   JOIN ${link_table} ON ${link_table}.pseudo_id1 = ppatients.pseudo_id1
   WHERE ppatient_id BETWEEN ${min_ppatientid} AND ${max_ppatientid}
   ORDER BY prescription_dataid"
#psql $DBNAME -t -A -F $'\037' -R $'\036\012' -c "$q" \
#  | sed '$ s/\(.\)$/\1\o36/' >public.prescription_data_all.out
psql $DBNAME -c "\copy ($q) TO 'public.prescription_data_linked.csv' CSV HEADER"

if [ -z "$REPSEUDOSALT" ]; then
  # linked original ppatients extract
  q="SELECT ppatients.* FROM ppatients
     JOIN ${link_table} ON ${link_table}.pseudo_id1 = ppatients.pseudo_id1
     WHERE e_batch_id between ${min_e_batchid} and ${max_e_batchid}
     ORDER BY id"
  psql $DBNAME -c "\copy ($q) TO 'public.ppatients_linked.csv' CSV HEADER"
else
  # linked repseudonymised ppatients extract, with repseudononymised ids shortened to 16 characters
  # Fields: id,e_batch_id,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2,pseudonymisation_keyid
  q="SELECT ppatients.id, ppatients.e_batch_id, ppatients.ppatient_rawdata_id, ppatients.type,
     CASE WHEN ppatients.pseudo_id1 IS NULL THEN NULL ELSE
       substr(encode(digest('pseudoid_' || ppatients.pseudo_id1 || '${REPSEUDOSALT}', 'sha256'),
                     'hex'), 1, 16)
     END AS pseudo_id1_short,
     CASE WHEN ppatients.pseudo_id2 IS NULL THEN NULL ELSE
       substr(encode(digest('pseudoid_' || ppatients.pseudo_id2 || '${REPSEUDOSALT}', 'sha256'),
                     'hex'), 1, 16)
     END AS pseudo_id2_short,
     ppatients.pseudonymisation_keyid
     FROM ppatients
     JOIN ${link_table} ON ${link_table}.pseudo_id1 = ppatients.pseudo_id1
     WHERE e_batch_id between ${min_e_batchid} and ${max_e_batchid}
     ORDER BY id"
  psql $DBNAME -c "\copy ($q) TO 'public.ppatients_linked_repseudo_short.csv' CSV HEADER"
fi



exit

# prescription_patientids[_prefix0]
q='SELECT * FROM prescription_patientids_prefix0'
psql prescriptions -t -A -F $'\037' -R $'\036\012' -c "$q" \
  | sed '$ s/\(.\)$/\1\o36/' >public.prescription_patientids_prefix0.out
