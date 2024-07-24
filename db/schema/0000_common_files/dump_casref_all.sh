#!/bin/bash

# dump tables for matched CASREF patients, for loading into CASREF (Oracle db).
# - on testdb:
#  20m31.114s
#
#   4920282 public.ppatients.out
#   4706373 public.prescription_data.out

# Database containing the prescription data
if [ -z "$DBNAME" ]; then
  DBNAME='testdb'
  echo Defaulting to DBNAME=$DBNAME
  export DBNAME
fi

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
  echo '(Use REPSEUDOSALT=full to extract full pseudo_ids instead of short values.)'
  read -p 'Enter REPSEUDOSALT [leave blank to not repseudonymise]: ' -rs REPSEUDOSALT
  echo
  if ! echo "$REPSEUDOSALT" | egrep -q '^([0-9a-f]{64}|full|short)?$' ; then
    echo "Error: Invalid REPSEUDOSALT: Expected blank or 64 hex characters or 'full' or 'short'"
    exit 1
  fi
  export REPSEUDOSALT
fi

if [ -z "$ETYPE" ]; then
  ETYPE='PSPRESCRIPTION'
  echo Defaulting to ETYPE=$ETYPE
  export ETYPE
fi

case $ETYPE in
    PSPRESCRIPTION)
        OTHER_TABLES=prescription_data
        FIELDS_prescription_data=prescription_data.prescription_dataid,prescription_data.ppatient_id,prescription_data.presc_date,prescription_data.part_month,prescription_data.presc_postcode,prescription_data.pco_code,prescription_data.pco_name,prescription_data.practice_code,prescription_data.practice_name,prescription_data.nic,prescription_data.presc_quantity,prescription_data.item_number,prescription_data.unit_of_measure,prescription_data.pay_quantity,prescription_data.drug_paid,prescription_data.bnf_code,prescription_data.pat_age,prescription_data.pf_exempt_cat,prescription_data.etp_exempt_cat,prescription_data.etp_indicator,prescription_data.pf_id,prescription_data.ampp_id,prescription_data.vmpp_id,prescription_data.sex,prescription_data.form_type,prescription_data.chemical_substance_bnf,prescription_data.chemical_substance_bnf_descr,prescription_data.vmp_id,prescription_data.vmp_name,prescription_data.vtm_name
        ;;
    PSMOLE)
        OTHER_TABLES=molecular_data
        FIELDS_molecular_data="molecular_data.molecular_dataid,molecular_data.ppatient_id,molecular_data.providercode,molecular_data.practitionercode,molecular_data.datefirstnotified,molecular_data.sourcetype,molecular_data.comments,molecular_data.requesteddate,molecular_data.collecteddate,molecular_data.receiveddate,molecular_data.authoriseddate,molecular_data.indicationcategory,molecular_data.clinicalindication,molecular_data.organisationcode_testresult,molecular_data.moleculartestingtype,molecular_data.servicereportidentifier,molecular_data.specimentype,molecular_data.otherspecimentype,molecular_data.tumourpercentage,molecular_data.specimenprep,molecular_data.karyotypingmethod,molecular_data.genetictestscope,molecular_data.isresearchtest,molecular_data.patienttype,molecular_data.raw_record,molecular_data.age"
        # No longer truncating raw_record to 4000 characters; now a CLOB field on CASREF
        # Ignore field molecular_data.genetictestresults - no longer used,
        # should be removed in a migration
        FIELDS_genetic_test_results="genetic_test_results.genetictestresultid,genetic_test_results.molecular_data_id,genetic_test_results.teststatus,genetic_test_results.geneticaberrationtype,genetic_test_results.karyotypearrayresult,genetic_test_results.rapidniptresult,genetic_test_results.gene,genetic_test_results.genotype,genetic_test_results.zygosity,genetic_test_results.chromosomenumber,genetic_test_results.chromosomearm,genetic_test_results.cytogeneticband,genetic_test_results.fusionpartnergene,genetic_test_results.fusionpartnerchromosomenumber,genetic_test_results.fusionpartnerchromosomearm,genetic_test_results.fusionpartnercytogeneticband,genetic_test_results.msistatus,genetic_test_results.report,genetic_test_results.geneticinheritance,genetic_test_results.percentmutantalabkaryotype,genetic_test_results.oncotypedxbreastrecurscore,genetic_test_results.raw_record,genetic_test_results.age"
        # No longer truncating raw_record to 4000 characters; now a CLOB field on CASREF
        FIELDS_genetic_sequence_variants="genetic_sequence_variants.geneticsequencevariantid,genetic_sequence_variants.genetic_test_result_id,genetic_sequence_variants.humangenomebuild,genetic_sequence_variants.referencetranscriptid,genetic_sequence_variants.genomicchange,genetic_sequence_variants.codingdnasequencechange,genetic_sequence_variants.proteinimpact,genetic_sequence_variants.clinvarid,genetic_sequence_variants.cosmicid,genetic_sequence_variants.variantpathclass,genetic_sequence_variants.variantlocation,genetic_sequence_variants.exonintroncodonnumber,genetic_sequence_variants.sequencevarianttype,genetic_sequence_variants.variantimpact,genetic_sequence_variants.variantreport,genetic_sequence_variants.variantgenotype,genetic_sequence_variants.variantallelefrequency,genetic_sequence_variants.raw_record,genetic_sequence_variants.age"
        # No longer truncating raw_record to 4000 characters; now a CLOB field on CASREF
        ;;
    *)
        OTHER_TABLES=""
esac
FIELDS_e_batch=e_batch.e_batchid,e_batch.e_type,e_batch.provider,e_batch.media,e_batch.original_filename,e_batch.cleaned_filename,e_batch.numberofrecords,e_batch.date_reference1,e_batch.date_reference2,e_batch.e_batchid_traced,e_batch.comments,e_batch.digest,e_batch.lock_version,e_batch.inprogress,e_batch.registryid,e_batch.on_hold
FIELDS_ppatients="ppatients.id AS ppatients_id,ppatients.e_batch_id,ppatients.ppatient_rawdata_id,ppatients.type,ppatients.pseudo_id1,ppatients.pseudo_id2,ppatients.pseudonymisation_keyid"
FIELDS_ppatients_short="ppatients.id AS ppatients_id,ppatients.e_batch_id,ppatients.ppatient_rawdata_id,ppatients.type,
     substr(ppatients.pseudo_id1, 1, 16) AS pseudo_id1_short,
     substr(ppatients.pseudo_id2, 1, 16) AS pseudo_id2_short,
     ppatients.pseudonymisation_keyid"

# Identify records to extract
q="select e_batchid, provider, original_filename, cleaned_filename
   from e_batch where e_type='$ETYPE' order by e_batchid"
psql $DBNAME -c "$q"

read -p "Enter min_e_batchid to extract: " min_e_batchid
read -p "Enter max_e_batchid to extract: " max_e_batchid

q="select min(id) as min_ppatientid, max(id) as max_ppatientid
   from ppatients left join e_batch on ppatients.e_batch_id = e_batch.e_batchid
   where e_type='$ETYPE' and e_batch_id between ${min_e_batchid} and ${max_e_batchid}"
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

# prescription_data extract
for other_table in $OTHER_TABLES; do
  fields_key="FIELDS_$other_table"
  q="SELECT ${!fields_key} FROM ${other_table}
     WHERE ppatient_id BETWEEN ${min_ppatientid} AND ${max_ppatientid}
     ORDER BY ${other_table}id"
  #psql $DBNAME -t -A -F $'\037' -R $'\036\012' -c "$q" \
  #  | sed '$ s/\(.\)$/\1\o36/' >public.${other_table}_all.out
  psql $DBNAME -c "\copy ($q) TO 'public.${other_table}_all.csv' CSV HEADER"
done

# Extra tables
if [ "$ETYPE" = "PSMOLE" ]; then
  other_table='genetic_test_results'
  fields_key="FIELDS_$other_table"
  q="SELECT ${!fields_key} FROM ${other_table}
     LEFT JOIN molecular_data ON ${other_table}.molecular_data_id = molecular_data.molecular_dataid
     WHERE ppatient_id BETWEEN ${min_ppatientid} AND ${max_ppatientid}
     ORDER BY genetictestresultid"
  psql $DBNAME -c "\copy ($q) TO 'public.${other_table}_all.csv' CSV HEADER"

  other_table='genetic_sequence_variants'
  fields_key="FIELDS_$other_table"
  q="SELECT ${!fields_key} FROM ${other_table}
     LEFT JOIN genetic_test_results ON ${other_table}.genetic_test_result_id = genetic_test_results.genetictestresultid
     LEFT JOIN molecular_data ON genetic_test_results.molecular_data_id = molecular_data.molecular_dataid
     WHERE ppatient_id BETWEEN ${min_ppatientid} AND ${max_ppatientid}
     ORDER BY genetictestresultid"
  psql $DBNAME -c "\copy ($q) TO 'public.${other_table}_all.csv' CSV HEADER"
fi

if [ -z "$REPSEUDOSALT" -o "$REPSEUDOSALT" = "short" ]; then
  # original ppatients extract, with shortened pseudo_ids
  fields_key="FIELDS_ppatients_short"
  q="SELECT ${!fields_key} FROM ppatients
     WHERE e_batch_id between ${min_e_batchid} and ${max_e_batchid}
     ORDER BY id"
  psql $DBNAME -c "\copy ($q) TO 'public.ppatients_all_short.csv' CSV HEADER"
elif [ "$REPSEUDOSALT" = "full" ]; then
  # original ppatients extract, with full pseudo_ids
  fields_key="FIELDS_ppatients"
  q="SELECT ${!fields_key} FROM ppatients
     WHERE e_batch_id between ${min_e_batchid} and ${max_e_batchid}
     ORDER BY id"
  psql $DBNAME -c "\copy ($q) TO 'public.ppatients_all.csv' CSV HEADER"
else
  # repseudonymised ppatients extract, with repseudononymised ids shortened to 16 characters
  # If this fails, you may need to run the following SQL first: CREATE EXTENSION pgcrypto;
  # Fields: id,e_batch_id,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2,pseudonymisation_keyid
  q="SELECT ppatients.id AS ppatients_id, ppatients.e_batch_id, ppatients.ppatient_rawdata_id, ppatients.type,
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
     WHERE e_batch_id between ${min_e_batchid} and ${max_e_batchid}
     ORDER BY id"
  psql $DBNAME -c "\copy ($q) TO 'public.ppatients_all_repseudo_short.csv' CSV HEADER"
fi

# Interactively in psql:
# \copy prescription_data TO 'public.prescription_data_all.out' csv HEADER
# \copy (SELECT prescription_data.* FROM prescription_data ORDER BY prescription_dataid) TO 'public.prescription_data_all2.out' csv HEADER
