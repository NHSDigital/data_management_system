LOAD DATA
CHARACTERSET UTF8
INFILE      'prescription_data.out'  "STR X'1E0A'"
BADFILE     'prescription_data.bad'
DISCARDFILE 'prescription_data.dsc'
APPEND  -- manually create/truncate table first
INTO TABLE prescriptionsample.prescription_data
FIELDS TERMINATED BY X'1F' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  prescription_dataid,
  ppatient_id,
  presc_date,
  part_month,
  presc_postcode,
  pco_code,
  pco_name,
  practice_code,
  practice_name,
  nic,
  presc_quantity,
  item_number,
  unit_of_measure,
  pay_quantity,
  drug_paid,
  bnf_code,
  pat_age,
  pf_exempt_cat,
  etp_exempt_cat,
  etp_indicator
)
