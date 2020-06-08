-- Load 4 tables generated by the prescription data preprocessor (create_prescr).
-- The tables must be defined with deferred constraints, to facilitate loading foreign-key fields directly
-- (see defer_constraints.sql).

BEGIN;

-- If you want to truncate the tables and reset the sequences first (e.g. for testing),
-- use truncate_tables.sql before executing this script.

-- e_batch record
-- FK ref ref zprovider, e_type
COPY e_batch (e_type,provider,media,original_filename,cleaned_filename,numberofrecords,
date_reference1,date_reference2,e_batchid_traced,comments,digest,
lock_version,inprogress,registryid,on_hold)
FROM '/path/to/e_batch.csv' CSV;

-- ppatient_rawdata
COPY ppatient_rawdata (rawdata,decrypt_key)
FROM '/path/to/ppatient_rawdata.csv' CSV;

-- ppatients
-- FK ref ppatient_rawdata deferred per-transaction
COPY ppatients (e_batch_id,ppatient_rawdata_id,type,pseudo_id1,pseudo_id2)
FROM '/path/to/ppatients_07.csv' CSV;

-- prescription_data
-- FK ref ppatients deferred per-transaction
COPY prescription_data (ppatient_id,presc_date,part_month,presc_postcode,pco_code,pco_name,
practice_code,practice_name,nic,presc_quantity,item_number,
unit_of_measure,pay_quantity,drug_paid,bnf_code,pat_age,
pf_exempt_cat,etp_exempt_cat,etp_indicator)
FROM '/path/to/prescription_data_07.csv' CSV;

COMMIT;

