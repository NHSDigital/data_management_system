LOAD DATA
CHARACTERSET UTF8
INFILE      'prescription_patientids_prefix0.out'  "STR X'1E0A'"
BADFILE     'prescription_patientids_prefix0.bad'
DISCARDFILE 'prescription_patientids_prefix0..dsc'
APPEND  -- manually create/truncate table first
INTO TABLE prescriptionsample.prescription_patientids_prefix0
FIELDS TERMINATED BY X'1F' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  PSEUDO_ID1,
  PATIENTID
)
