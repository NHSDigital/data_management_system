-- Example data file generation:
-- psql <database> -t -A -F $'\037' -R $'\036\012' -c 'select * from ppatient_rawdata' \
--   | sed '$ s/\(.\)$/\1\o36/' | sed 's/\\x//g' >ppatient_rawdata.out

-- Example loader invocation:
-- sqlldr <username>@<host> control=ppatient_rawdata.ctl \
--   bad=ppatient_rawdata.bad log=ppatient_rawdata.log errors=10000000 direct=true

LOAD DATA
CHARACTERSET UTF8
INFILE      'ppatient_rawdata.out'  "STR X'1E0A'"
BADFILE     'ppatient_rawdata.bad'
DISCARDFILE 'ppatient_rawdata.dsc'
APPEND  -- manually create/truncate table first
INTO TABLE ppatient_rawdata
FIELDS TERMINATED BY X'1F' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  ppatient_rawdataid,
  rawdata,
  decrypt_key
)
