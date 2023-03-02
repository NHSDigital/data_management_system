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
echo Data checksum: $(cd "$FILEPATH"; find . -type f -name '*.pseudo' -print0|LC_ALL=C sort -z|xargs -0 md5sum|cut -c-32|md5sum|cut -c-32)

echo Record counts: $(bundle exec rails runner "p [EBatch, Pseudo::Ppatient, Pseudo::GeneticTestResult, Pseudo::GeneticSequenceVariant].collect { |klass| [klass.name, klass.count] }.to_h" 2>/dev/null)

PGPASSWORD=$(bundle exec rails runner "cfg=ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'primary').configuration_hash; puts(cfg[:password])" 2>/dev/null)
PSQL_OPTIONS=$(bundle exec rails runner "cfg=ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'primary').configuration_hash; puts(cfg[:database] + ' -h ' + cfg[:host] + ' -U ' + cfg[:username])" 2>/dev/null)

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

SQL_FS_MMR="
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
run_sql "$SQL_FS_MMR"

SQL_TG_MMR="
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
run_sql "$SQL_TG_MMR"

SQL_UNABLE_MMR="
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
 INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%Unable%MMR%' group by gene order by 1;
"
run_sql "$SQL_UNABLE_MMR"

SQL_FS_BRCA="
select CASE WHEN gene::integer=7 THEN 'BRCA1'
WHEN gene::integer=8 THEN 'BRCA2'
WHEN gene::integer=451 THEN 'ATM'
WHEN gene::integer=794 THEN 'CDH1'
WHEN gene::integer=865 THEN 'CHEK2'
WHEN gene::integer=3186 THEN 'PALB2'
WHEN gene::integer=79 THEN 'TP53'
WHEN gene::integer=2744 THEN 'MLH1'
WHEN gene::integer=2804 THEN 'MSH2'
WHEN gene::integer=2808 THEN 'MSH6'
WHEN gene::Integer=3394 THEN 'PMS2'
WHEN gene::Integer=62 THEN 'PTEN'
WHEN gene::Integer=76 THEN 'STK11'
WHEN gene::Integer=590 THEN 'BRIP1'
WHEN gene::Integer=2912 THEN 'NBN'
WHEN gene::Integer=3615 THEN 'RAD51C'
WHEN gene::Integer=3616 THEN 'RAD51D'
WHEN gene::Integer=20 THEN 'CDKN2A'
WHEN gene::Integer=18 THEN 'CDK4'
WHEN gene::Integer=1432 THEN 'EPCAM'
WHEN gene::Integer=2850 THEN 'MUTYH'
WHEN gene::Integer=54 THEN 'NF1'
WHEN gene::Integer=55 THEN 'NF2'
WHEN gene::Integer=74 THEN 'SMARCB1'
WHEN gene::Integer=4952 THEN 'LZTR1'
WHEN gene::Integer=72 THEN 'SMAD4'
WHEN gene::Integer=358 THEN 'APC'
WHEN gene::Integer=517 THEN 'BAP1'
WHEN gene::Integer=577 THEN 'BMPR1A'
WHEN gene::Integer=1590 THEN 'FH'
WHEN gene::Integer=1603 THEN 'FLCN'
WHEN gene::Integer=1882 THEN 'GREM1'
WHEN gene::Integer=50 THEN 'MET'
WHEN gene::Integer=3108 THEN 'NTHL1'
WHEN gene::Integer=3408 THEN 'POLD1'
WHEN gene::Integer=5000 THEN 'POLE'
WHEN gene::Integer=68 THEN 'SDHB'
WHEN gene::Integer=83 THEN 'VHL'
 END AS genes,
count(distinct(md.servicereportidentifier))
 FROM (molecular_data md INNER JOIN genetic_test_results gtr
 ON md.molecular_dataid = gtr.molecular_data_id
 INNER JOIN ppatients pp ON pp.id = md.ppatient_id
 INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%Full%BRCA%' GROUP BY gene order by 1;
"
run_sql "$SQL_FS_BRCA"

SQL_TG_BRCA="
select CASE WHEN gene::integer=7 THEN 'BRCA1'
WHEN gene::integer=8 THEN 'BRCA2'
WHEN gene::integer=451 THEN 'ATM'
WHEN gene::integer=794 THEN 'CDH1'
WHEN gene::integer=865 THEN 'CHEK2'
WHEN gene::integer=3186 THEN 'PALB2'
WHEN gene::integer=79 THEN 'TP53'
WHEN gene::integer=2744 THEN 'MLH1'
WHEN gene::integer=2804 THEN 'MSH2'
WHEN gene::integer=2808 THEN 'MSH6'
WHEN gene::Integer=3394 THEN 'PMS2'
WHEN gene::Integer=62 THEN 'PTEN'
WHEN gene::Integer=76 THEN 'STK11'
WHEN gene::Integer=590 THEN 'BRIP1'
WHEN gene::Integer=2912 THEN 'NBN'
WHEN gene::Integer=3615 THEN 'RAD51C'
WHEN gene::Integer=3616 THEN 'RAD51D'
WHEN gene::Integer=20 THEN 'CDKN2A'
WHEN gene::Integer=18 THEN 'CDK4'
WHEN gene::Integer=1432 THEN 'EPCAM'
WHEN gene::Integer=2850 THEN 'MUTYH'
WHEN gene::Integer=54 THEN 'NF1'
WHEN gene::Integer=55 THEN 'NF2'
WHEN gene::Integer=74 THEN 'SMARCB1'
WHEN gene::Integer=4952 THEN 'LZTR1'
WHEN gene::Integer=72 THEN 'SMAD4'
WHEN gene::Integer=358 THEN 'APC'
WHEN gene::Integer=517 THEN 'BAP1'
WHEN gene::Integer=577 THEN 'BMPR1A'
WHEN gene::Integer=1590 THEN 'FH'
WHEN gene::Integer=1603 THEN 'FLCN'
WHEN gene::Integer=1882 THEN 'GREM1'
WHEN gene::Integer=50 THEN 'MET'
WHEN gene::Integer=3108 THEN 'NTHL1'
WHEN gene::Integer=3408 THEN 'POLD1'
WHEN gene::Integer=5000 THEN 'POLE'
WHEN gene::Integer=68 THEN 'SDHB'
WHEN gene::Integer=83 THEN 'VHL'
END AS genes,
 count(distinct(md.servicereportidentifier))
 FROM (molecular_data md INNER JOIN genetic_test_results gtr
 ON md.molecular_dataid = gtr.molecular_data_id
 INNER JOIN ppatients pp ON pp.id = md.ppatient_id
 INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where (genetictestscope like '%Targ%BRCA%'  or genetictestscope like '%AJ%BRCA%') GROUP BY gene order by 1;
"
run_sql "$SQL_TG_BRCA"


SQL_UNABLE_BRCA="select CASE WHEN gene::integer=7 THEN 'BRCA1'
WHEN gene::integer=8 THEN 'BRCA2'
WHEN gene::integer=451 THEN 'ATM'
WHEN gene::integer=794 THEN 'CDH1'
WHEN gene::integer=865 THEN 'CHEK2'
WHEN gene::integer=3186 THEN 'PALB2'
WHEN gene::integer=79 THEN 'TP53'
WHEN gene::integer=2744 THEN 'MLH1'
WHEN gene::integer=2804 THEN 'MSH2'
WHEN gene::integer=2808 THEN 'MSH6'
WHEN gene::Integer=3394 THEN 'PMS2'
WHEN gene::Integer=62 THEN 'PTEN'
WHEN gene::Integer=76 THEN 'STK11'
WHEN gene::Integer=590 THEN 'BRIP1'
WHEN gene::Integer=2912 THEN 'NBN'
WHEN gene::Integer=3615 THEN 'RAD51C'
WHEN gene::Integer=3616 THEN 'RAD51D'
WHEN gene::Integer=20 THEN 'CDKN2A'
WHEN gene::Integer=18 THEN 'CDK4'
WHEN gene::Integer=1432 THEN 'EPCAM'
WHEN gene::Integer=2850 THEN 'MUTYH'
WHEN gene::Integer=54 THEN 'NF1'
WHEN gene::Integer=55 THEN 'NF2'
WHEN gene::Integer=74 THEN 'SMARCB1'
WHEN gene::Integer=4952 THEN 'LZTR1'
WHEN gene::Integer=72 THEN 'SMAD4'
WHEN gene::Integer=358 THEN 'APC'
WHEN gene::Integer=517 THEN 'BAP1'
WHEN gene::Integer=577 THEN 'BMPR1A'
WHEN gene::Integer=1590 THEN 'FH'
WHEN gene::Integer=1603 THEN 'FLCN'
WHEN gene::Integer=1882 THEN 'GREM1'
WHEN gene::Integer=50 THEN 'MET'
WHEN gene::Integer=3108 THEN 'NTHL1'
WHEN gene::Integer=3408 THEN 'POLD1'
WHEN gene::Integer=5000 THEN 'POLE'
WHEN gene::Integer=68 THEN 'SDHB'
WHEN gene::Integer=83 THEN 'VHL'
END AS genes,
 count(distinct(md.servicereportidentifier))
 FROM (molecular_data md INNER JOIN genetic_test_results gtr
 ON md.molecular_dataid = gtr.molecular_data_id
 INNER JOIN ppatients pp ON pp.id = md.ppatient_id
 INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id) where genetictestscope like '%Unable%BRCA%' GROUP BY gene order by 1;
"
run_sql "$SQL_UNABLE_BRCA"

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


