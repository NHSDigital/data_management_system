#!/bin/bash

if [ ! $# = 2 ]; then
    echo "Syntax: `basename "$0"` '~/work/mbis' private/pseudonymised_data/updated_files/"
    exit 1
fi

DIRPATH="$1"
cd "$1"
FILEPATH="$2"
echo Code revision: $(git rev-parse HEAD 2>/dev/null || cat REVISION)
echo Data revision: $(cd "$FILEPATH"; svnversion)
echo Data checksum: $(cd "$FILEPATH"; find . -type f -print0|LC_ALL=C sort -z|xargs -0 md5sum|cut -c-32|md5sum|cut -c-32)

echo Record counts: $(bundle exec rails runner "p [EBatch, Pseudo::Ppatient, Pseudo::GeneticTestResult, Pseudo::GeneticSequenceVariant].collect { |klass| [klass.name, klass.count] }.to_h" 2>/dev/null)

PGPASSWORD=$(bundle exec rails runner "cfg=ActiveRecord::Base.configurations.default_hash; puts(cfg['password'])" 2>/dev/null)
PSQL_OPTIONS=$(bundle exec rails runner "cfg=ActiveRecord::Base.configurations.default_hash; puts(cfg['database'] + ' -h ' + cfg['host'] + ' -U ' + cfg['username'])" 2>/dev/null)

function run_sql {
  PGPASSWORD="$PGPASSWORD" psql $PSQL_OPTIONS -e -c "$1" | cat
}

SQL="
select version();
"
run_sql "$SQL"

SQL="
select distinct(provider) from e_batch order by provider;
"
run_sql "$SQL"

SQL="
select count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
FROM (molecular_data md INNER JOIN genetic_test_results gtr
ON md.molecular_dataid = gtr.molecular_data_id
INNER JOIN ppatients pp ON pp.id = md.ppatient_id
INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%BRCA%';
"
run_sql "$SQL"

SQL="
select count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
FROM (molecular_data md INNER JOIN genetic_test_results gtr
ON md.molecular_dataid = gtr.molecular_data_id
INNER JOIN ppatients pp ON pp.id = md.ppatient_id
INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%MMR%';
"
run_sql "$SQL"

SQL="
select CASE WHEN gene='358' THEN  'APC'
  WHEN gene='577' THEN  'BMPR1A'
  WHEN gene='1432' THEN  'EPCAM'
  WHEN gene='2744' THEN  'MLH1'
  WHEN gene='2804' THEN  'MSH2'
  WHEN gene='2808' THEN  'MSH6'
  WHEN gene='2850' THEN  'MUTYH'
  WHEN gene='3394' THEN  'PMS2'
  WHEN gene='3408' THEN  'POLD1'
  WHEN gene='5000' THEN  'POLE'
  WHEN gene='62' THEN  'PTEN'
  WHEN gene='72' THEN  'SMAD4'
  WHEN gene='76' THEN  'STK11'
  WHEN gene='1882' THEN  'GREM1'
  WHEN gene='3108' THEN  'NTHL1'
  END AS gene,
  count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
  FROM (molecular_data md INNER JOIN genetic_test_results gtr
  ON md.molecular_dataid = gtr.molecular_data_id
  INNER JOIN ppatients pp ON pp.id = md.ppatient_id
  INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%Full%MMR%' group by gene order by 1;
"
run_sql "$SQL"

SQL="
select CASE WHEN gene='358' THEN  'APC'
 WHEN gene='577' THEN  'BMPR1A'
 WHEN gene='1432' THEN  'EPCAM'
 WHEN gene='2744' THEN  'MLH1'
 WHEN gene='2804' THEN  'MSH2'
 WHEN gene='2808' THEN  'MSH6'
 WHEN gene='2850' THEN  'MUTYH'
 WHEN gene='3394' THEN  'PMS2'
 WHEN gene='3408' THEN  'POLD1'
 WHEN gene='5000' THEN  'POLE'
 WHEN gene='62' THEN  'PTEN'
 WHEN gene='72' THEN  'SMAD4'
 WHEN gene='76' THEN  'STK11'
 WHEN gene='1882' THEN  'GREM1'
 WHEN gene='3108' THEN  'NTHL1'
 END AS gene,
 count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
 FROM (molecular_data md INNER JOIN genetic_test_results gtr
 ON md.molecular_dataid = gtr.molecular_data_id
 INNER JOIN ppatients pp ON pp.id = md.ppatient_id
 INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%Targ%MMR%' group by gene order by 1;
"
run_sql "$SQL"

SQL="
select provider, count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
FROM (molecular_data md INNER JOIN genetic_test_results gtr
ON md.molecular_dataid = gtr.molecular_data_id
INNER JOIN ppatients pp ON pp.id = md.ppatient_id
INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%MMR%'
GROUP BY provider ORDER BY provider;
"
run_sql "$SQL"

SQL="
select provider, count(distinct(pseudo_id1,pseudo_id2,servicereportidentifier))
FROM (molecular_data md INNER JOIN genetic_test_results gtr
ON md.molecular_dataid = gtr.molecular_data_id
INNER JOIN ppatients pp ON pp.id = md.ppatient_id
INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope is null or genetictestscope like '%BRCA%'
GROUP BY provider ORDER BY provider;
"
run_sql "$SQL"


SQL="
select provider, digest, count(distinct(pp.id)) as ppatientids,
       count(distinct(gtr.genetictestresultid)) as genetictestresultids
FROM (molecular_data md INNER JOIN genetic_test_results gtr
ON md.molecular_dataid = gtr.molecular_data_id
INNER JOIN ppatients pp ON pp.id = md.ppatient_id
INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id)
GROUP BY provider, digest ORDER BY provider, digest;
"
run_sql "$SQL"
