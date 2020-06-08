-- Example data file generation:
-- psql <database> -t -A -F $'\037' -R $'\036\012' -c 'select * from ppatients' \
--   | sed '$ s/\(.\)$/\1\o36/' >ppatients.out

-- Example loader invocation:
-- sqlldr <username>@<host> control=ppatients.ctl \
--   bad=ppatients.bad log=ppatients.log errors=10000000 direct=true

LOAD DATA
CHARACTERSET UTF8
INFILE      'ppatients.out'  "STR X'1E0A'"
BADFILE     'ppatients.bad'
DISCARDFILE 'ppatients.dsc'
APPEND  -- manually create/truncate table first
INTO TABLE prescriptionsample.ppatients
FIELDS TERMINATED BY X'1F' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  ppatients_id,
  e_batch_id,
  ppatient_rawdata_id,
  type,
  pseudo_id1,
  pseudo_id2
)
