-- Create the table for full screen frequencies by provider, as specified by Fiona.
-- This script produces the final result in two pieces, which are assembled bash script

BEGIN; 

-------------------------------------------------------------------------
-- This table extracts the pseudo id pairs that are shared between     --
-- Leeds and Newcastle. These indicate samples sent out from Newcastle --
-- to Leeds for processing, so we don't want to double count them      --
-------------------------------------------------------------------------

CREATE TEMP TABLE overlap_ids ON COMMIT DROP AS (
WITH leeds_ids AS (
SELECT pseudo_id1 AS id1,
       pseudo_id2 AS id2
FROM (
       molecular_data md
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id
)
WHERE provider='RR8'
),    
newcastle_ids AS (
SELECT pseudo_id1 AS id1,
       pseudo_id2 AS id2
FROM (
       molecular_data md
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id
)
WHERE provider='RTD'
),
overlap_ids AS (
SELECT li.id1, li.id2
FROM (
       leeds_ids li INNER JOIN newcastle_ids ni ON ni.id1 = li.id1 AND ni.id2 = li.id2)
) 
SELECT * FROM overlap_ids
);

--------------------------------------------------------------------------------------------
-- Create flat result-level tables which correctly handle the leeds-newcaslte duplicaters --
--------------------------------------------------------------------------------------------

CREATE temp TABLE restricted_results_all ON COMMIT DROP AS (

SELECT pseudo_id1,
       pseudo_id2,
       --     provider,
       CASE WHEN provider='RTD'
            AND concat(pseudo_id1, pseudo_id2) IN (SELECT concat(id1, id2) FROM overlap_ids)
            THEN 'RTD-RR8'
            ELSE provider END,
       gene,
       genetictestresultid,
       genetictestscope,
       moleculartestingtype,
       teststatus,
       molecular_dataid
       FROM (
       molecular_data md INNER JOIN genetic_test_results gtr
       ON md.molecular_dataid = gtr.molecular_data_id
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id)
       WHERE (provider<>'RR8' OR
              concat(pseudo_id1, pseudo_id2) NOT IN (SELECT concat(id1, id2) FROM overlap_ids)) 
); 
-- This table includes all the results, with the aforementioned duplicates excluded
CREATE TEMP TABLE restricted_results ON COMMIT DROP AS (
       SELECT * FROM restricted_results_all
       WHERE genetictestscope LIKE 'Full%'     
);


-- TODO: The validation logic could be improved to make sure we have at least one result for each gene
-- for each person listed

-------------------------------------------------------------------------------------------
-- The TABLE format FOR the summary OF variant counts Fiona requested IS diffcult TO     --
-- CREATE IN SQL alone, so a bash script glues the pieces together. The code immediately --
-- below produes the header summaries, detailing the total NUMBER OF patients who        --
-- received diagnostic test, BY provider.                                                --
-------------------------------------------------------------------------------------------
CREATE TEMP TABLE header_summary ON COMMIT DROP AS (
WITH alpha AS (
SELECT pseudo_id1,
       pseudo_id2,
       provider
       --string_agg(DISTINCT provider, ',') AS prov
FROM restricted_results
GROUP BY pseudo_id1, pseudo_id2, provider --HAVING COUNT(*)>1
),
screening_counts AS (
SELECT provider AS prov, COUNT(*) FROM alpha
GROUP BY prov)
SELECT
        'Full screen counts' AS label,null a,null b,null c, NULL d,null e,
        AVG(CASE WHEN prov='RQ3' THEN count END)::integer AS RQ3,
        AVG(CASE WHEN prov='RVJ' THEN count END)::integer AS RVJ,
        AVG(CASE WHEN prov='RGT' THEN count END)::integer AS RGT,
        AVG(CASE WHEN prov='RJ1' THEN count END)::integer AS RJ1,
        AVG(Case WHEN prov='RR8' THEN count END)::integer AS RR8,
        AVG(CASE WHEN prov='RTD-RR8' THEN count END)::integer AS RTD_RR8,       
        AVG(CASE WHEN prov='RTD' THEN count END)::integer AS RTD,       
        AVG(CASE WHEN prov='R0a' THEN count END)::integer AS R0A,
        AVG(CASE WHEN prov='RX1' THEN count END)::integer AS RX1, 
        AVG(CASE WHEN prov='RNZ' THEN count END)::integer AS RNZ, 
        AVG(CASE WHEN prov='RCU' THEN count END)::integer AS RCU 
FROM screening_counts
GROUP BY label,a,b,c,d,e
);

------------------------------------------------------------------------------------------
-- This IS a helper TABLE, a flat TABLE OF variants WITH the leeds-newcaslte duplciates --
-- handled                                                                              --
------------------------------------------------------------------------------------------
CREATE TEMP TABLE  restricted_variants ON COMMIT DROP AS (
SELECT pseudo_id1,
       pseudo_id2,
       codingdnasequencechange,
       gene,
       proteinimpact,
       variantpathclass,
       moleculartestingtype,
       genetictestscope,
       CASE WHEN provider='RTD'
            AND concat(pseudo_id1, pseudo_id2) IN (SELECT concat(id1, id2) FROM overlap_ids)
            THEN 'RTD-RR8'
            ELSE provider END,
       gsv.raw_record AS raw_record,
       gsv.exonintroncodonnumber,
       molecular_dataid
       FROM (
       molecular_data md INNER JOIN genetic_test_results gtr
       ON md.molecular_dataid = gtr.molecular_data_id
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id
       INNER JOIN genetic_sequence_variants gsv
             ON gsv.genetic_test_result_id = gtr.genetictestresultid)
       WHERE (provider<>'RR8' OR
       concat(pseudo_id1, pseudo_id2) NOT IN (SELECT concat(id1, id2) FROM overlap_ids))
);

---------------------------------------------------------------------------
-- Summarize information BY mutation, AND remove clearly non-pathogenic  --
---------------------------------------------------------------------------
CREATE temp TABLE restricted_variants_no_null_class ON COMMIT DROP AS (
       SELECT
       pseudo_id1,
       pseudo_id2,
       codingdnasequencechange,
       gene,
       proteinimpact,
       CASE WHEN variantpathclass IS NULL THEN 2000
       ELSE variantpathclass END AS variantpathclass,
       moleculartestingtype,
       genetictestscope,
       provider,
       raw_record,
       exonintroncodonnumber
       FROM restricted_variants
);
CREATE TEMP TABLE variant_info ON COMMIT DROP AS (
SELECT codingdnasequencechange AS dna,
       codingdnasequencechange,
       gene,
       COUNT(*) AS observed_count,
       string_agg(DISTINCT proteinimpact, ',') AS impact,
       string_agg(DISTINCT variantpathclass::text, ',') AS variantclass
FROM restricted_variants_no_null_class
WHERE codingdnasequencechange IS NOT NULL
      AND gene IS NOT NULL
GROUP BY codingdnasequencechange, gene
HAVING CASE 
       WHEN MAX(variantpathclass) IS NULL
              THEN TRUE
       WHEN (MAX(variantpathclass)>2 AND MAX(variantpathclass) < 6)
            THEN TRUE
       WHEN MAX(variantpathclass) > 6
            THEN TRUE 
       ELSE FALSE
       END 
ORDER BY observed_count
);

----------------------------------------------------------------------------
-- This generates the same counts, but only for instances of full screens --
----------------------------------------------------------------------------


CREATE temp TABLE full_screen_counts ON COMMIT DROP AS (
SELECT codingdnasequencechange AS dna, gene, COUNT(*) AS observed_count
FROM restricted_variants_no_null_class
WHERE codingdnasequencechange IS NOT NULL
      AND gene IS NOT NULL
      AND genetictestscope LIKE 'Full%'
GROUP BY codingdnasequencechange, gene
HAVING  CASE 
       WHEN MAX(variantpathclass) IS NULL
              THEN TRUE
       WHEN (MAX(variantpathclass)>2 AND MAX(variantpathclass) < 6)
            THEN TRUE
       WHEN MAX(variantpathclass) > 6
            THEN TRUE 
       ELSE FALSE
       END 
ORDER BY observed_count
);

-----------------------------------------------------------------
-- This aggregates the non-provider-specific table information --
-----------------------------------------------------------------

CREATE temp TABLE left_side ON COMMIT DROP AS (SELECT vi.dna,
       impact, 
       vi.gene,
       variantclass,
       vi.observed_count AS total_count,
       fc.observed_count AS full_screen_count
FROM (variant_info vi INNER JOIN full_screen_counts fc
ON fc.dna = vi.dna AND fc.gene = vi.gene)
ORDER BY fc.observed_count DESC
);

-- generate counts for each sequence variant by provider
CREATE temp TABLE center_counts ON COMMIT DROP AS (
SELECT provider,
       --rr.gene,
       gene,
       codingdnasequencechange,
       COUNT(*)
       FROM 
    --   (restricted_results rr INNER JOIN genetic_sequence_variants gsv
    --   ON rr.genetictestresultid = gsv.genetic_test_result_id)
       restricted_variants
       WHERE codingdnasequencechange IS NOT NULL
       AND gene IS NOT NULL
       AND genetictestscope LIKE 'Full%'
       GROUP BY codingdnasequencechange, gene, provider
       ORDER BY provider,count);

-- reshape that table as specified for the summary
CREATE temp TABLE center_counts_by_change ON COMMIT DROP AS      
(SELECT
        codingdnasequencechange,
        gene,
        AVG(CASE WHEN provider='RQ3' THEN count END)::integer AS RQ3,
        AVG(CASE WHEN provider='RNZ' THEN count END)::integer AS RNZ,
        AVG(CASE WHEN provider='RGT' THEN count END)::integer AS RGT,
        AVG(CASE WHEN provider='R1K' THEN count END)::integer AS R1K,
        AVG(CASE WHEN provider='RR8' THEN count END)::integer AS RR8,
        AVG(CASE WHEN provider='RTD-RR8' THEN count END)::integer AS RTD_RR8,
        AVG(CASE WHEN provider='R0A' THEN count END)::integer AS RA0,
        AVG(CASE WHEN provider='RTD' THEN count END)::integer AS RTD,
        AVG(CASE WHEN provider='RX1' THEN count END)::integer AS RX1,
        AVG(CASE WHEN provider='RNZ' THEN count END)::integer AS RNZ,
        AVG(CASE WHEN provider='RCU' THEN count END)::integer AS RCU,
        AVG(CASE WHEN provider='RPY' THEN count END)::integer AS RPY,
        AVG(CASE WHEN provider='RP4' THEN count END)::integer AS RP4,
        AVG(CASE WHEN provider='RTH' THEN count END)::integer AS RTH
FROM center_counts
GROUP BY codingdnasequencechange, gene);
-- Put all the pieces together
CREATE TEMP TABLE results_table ON COMMIT DROP AS (
SELECT dna,
       impact,
	   CASE WHEN ls.gene::integer=358 THEN 'APC'
	   WHEN ls.gene::integer=577 THEN 'BMPR1A'
	   WHEN ls.gene::integer=1432 THEN 'EPCAM'
	   WHEN ls.gene::integer=2744 THEN 'MLH1'
	   WHEN ls.gene::integer=2804 THEN 'MSH2'
	   WHEN ls.gene::integer=2808 THEN 'MSH6'
	   WHEN ls.gene::integer=2850 THEN 'MUTYH'
	   WHEN ls.gene::integer=3394 THEN 'PMS2'
	   WHEN ls.gene::integer=3408 THEN 'POLD1'
	   WHEN ls.gene::integer=5000 THEN 'POLE'
	   WHEN ls.gene::integer=62 THEN 'PTEN'
	   WHEN ls.gene::integer=72 THEN 'SMAD4'
	   WHEN ls.gene::integer=76 THEN 'STK11'
	   WHEN ls.gene::integer=1882 THEN 'GREM1'
	   WHEN ls.gene::integer=3108 THEN 'NTHL1'
	     END AS gene,
       variantclass,
       total_count ,
       full_screen_count ,
       rq3 , rvj , rgt , rj1 , rr8 , rtd_rr8, rtd , rw3, rx1 , rnz , rcu  FROM 
(
        left_side ls INNER JOIN center_counts_by_change ccc
                  ON ls.dna = ccc.codingdnasequencechange AND ls.gene = ccc.gene
)
ORDER BY full_screen_count DESC);

-- Save the two pieces to file, to be assembled by bash script
\COPY (SELECT * FROM results_table ) TO 'output/main_table.csv' WITH csv header delimiter ','; 
\COPY (SELECT * FROM header_summary ) TO 'output/table_totals.csv' WITH csv header delimiter ','; 

-- If these two numbers do not agree, something is wrong and improper duplicates are present
SELECT COUNT(*) FROM (SELECT dna, gene FROM results_table
GROUP BY dna, gene ) s
;
SELECT COUNT(*) FROM results_table;

--------------------------------------------------
-- Additional pre-summary information FOR Diana --
--------------------------------------------------

CREATE TEMP TABLE restricted_variants_3 ON COMMIT DROP AS (
       SELECT
       rv.codingdnasequencechange,
       rv.gene,
       rv.proteinimpact,
       rv.variantpathclass,
       rv.moleculartestingtype,
       rv.genetictestscope,
       rv.provider
       FROM 
       restricted_variants rv INNER JOIN variant_info vi
       ON rv.codingdnasequencechange = vi.codingdnasequencechange
       AND rv.gene = vi.gene);
       
-- Number of useful providers
\echo "Number OF useful providers"
SELECT COUNT(*) FROM (
SELECT provider FROM restricted_variants
WHERE codingdnasequencechange IS NOT NULL
GROUP BY provider) s;

-- Number of patients with diagnostic testing
\echo "Number OF patients WITH diagnostic testing"
SELECT COUNT(*) FROM (SELECT pseudo_id1, pseudo_id2 FROM restricted_results
WHERE genetictestscope LIKE 'Full%' 
GROUP BY pseudo_id1, pseudo_id2) s;

-- Number of variants observed exactly once
\echo "Number OF variants observed exactly once"
SELECT COUNT(*) FROM (SELECT codingdnasequencechange, gene FROM restricted_variants_3
WHERE genetictestscope LIKE 'Full%'
GROUP BY codingdnasequencechange, gene HAVING COUNT(*)=1) s; 

-- Number of variants
\echo "Number OF variants"
SELECT COUNT(*) FROM restricted_variants_3 WHERE codingdnasequencechange IS NOT NULL AND genetictestscope LIKE 'Full%';

-- Figure out how many variants have both types of test, and in what numbers
CREATE TEMP TABLE pred_diag ON COMMIT DROP AS (
WITH fres AS (SELECT codingdnasequencechange,
       gene,
       genetictestscope,
       COUNT(*)
       FROM restricted_variants_3
GROUP BY codingdnasequencechange, gene, genetictestscope)
SELECT codingdnasequencechange,
       gene,
       AVG(CASE WHEN genetictestscope LIKE 'Full%' THEN count END)::integer AS diagnostic,
       AVG(CASE WHEN genetictestscope LIKE 'Targ%' THEN count END)::integer AS predictive
FROM fres
WHERE codingdnasequencechange IS NOT NULL AND gene IS NOT NULL
GROUP BY codingdnasequencechange, gene
ORDER BY diagnostic);

\echo "Number OF variants WITH BOTH a diagnostic AND predictive test"
SELECT COUNT(*) FROM pred_diag
WHERE diagnostic IS NOT NULL AND predictive IS NOT NULL
;

\echo "Same, but WITH count > 5"
SELECT COUNT(*) FROM pred_diag pd
INNER JOIN (SELECT codingdnasequencechange, gene, COUNT(*) AS varcount FROM restricted_variants GROUP BY codingdnasequencechange, gene) s1 ON s1.codingdnasequencechange = pd.codingdnasequencechange AND pd.gene = s1.gene
WHERE varcount > 5;

-- Variant number table
\echo "Variant count table"

CREATE temp TABLE variant_counts ON COMMIT DROP AS
(WITH classes AS (SELECT codingdnasequencechange, gene, string_agg(DISTINCT variantpathclass::text, ',') AS variantpathclass FROM restricted_variants_3
WHERE genetictestscope LIKE 'Full%' AND codingdnasequencechange IS NOT NULL
GROUP BY codingdnasequencechange, gene)
SELECT variantpathclass, COUNT(*) FROM
classes
GROUP BY variantpathclass
ORDER BY count);

\COPY ( SELECT * FROM variant_counts ) TO 'output/variant_counts.csv' WITH csv header delimiter ','
;

\echo "Number OF targeted tests, ON variants CLASS 3 and up"
SELECT COUNT(*) FROM restricted_variants_3
WHERE genetictestscope LIKE 'Targ%';

\echo "Providers sending benign variants"
-- Providers sending benign variants
SELECT provider, COUNT(DISTINCT codingdnasequencechange) FROM restricted_variants
WHERE variantpathclass IS NOT NULL AND variantpathclass < 3
GROUP BY provider;

\echo "Abnormal percentage by lab"


--------------------------------------------------------------------
-- Provider counts (FULL screen)                                  --
-- Calculate the NUMBER OF variants seen BY EACH provider, AS a   --
-- fraction OF the total NUMBER OF people who received diagnostic --
-- tests                                                          --
--------------------------------------------------------------------

CREATE temp TABLE prov_counts ON COMMIT DROP AS (
WITH var_counts AS (SELECT provider,
       COUNT(*)
FROM
        restricted_variants
WHERE genetictestscope LIKE 'Full%'
AND (variantpathclass IS NULL
OR  (variantpathclass > 2 AND variantpathclass < 6) -- Annoyingly, 6 corresponds to class 1/2...
OR  variantpathclass > 6)
AND codingdnasequencechange IS NOT NULL
AND gene IS NOT NULL 
GROUP BY provider
ORDER BY provider)
,
total_counts AS (
SELECT provider, COUNT(*) FROM (SELECT pseudo_id1, pseudo_id2, provider AS provider FROM restricted_results
WHERE genetictestscope LIKE 'Full%' 
GROUP BY pseudo_id1, pseudo_id2,  provider) s1
GROUP BY provider
)
SELECT tc.provider,
       --       round((CAST(vc.count AS float) / CAST(tc.count AS float))::numeric, 3),
       (CAST(vc.count AS float) / CAST(tc.count AS float))::numeric,
       vc.count AS var_count,
       tc.count AS total_count
FROM total_counts tc INNER JOIN var_counts vc
     ON tc.provider = vc.provider)
     
;

\COPY ( SELECT * FROM prov_counts ) TO 'output/prov_counts.csv' WITH csv header delimiter ','; 

-------------------------------------------------------------------------------
-- Provider counts (targeted tests)                                          --
-- Calculate the NUMBER OF variants (NOT unique) seen BY EACH provider, AS a --
-- fraction OF the total NUMBER OF people who received predictive            --
-- tests                                                                     --
-------------------------------------------------------------------------------

CREATE temp TABLE prov_counts_targeted ON COMMIT DROP AS (
WITH var_counts AS (SELECT provider,
       COUNT(*)
FROM
        restricted_variants
WHERE (genetictestscope LIKE 'Targeted%' OR
      genetictestscope LIKE 'AJ %' OR
      genetictestscope LIKE 'Polish%') 
AND (variantpathclass IS NULL
OR  (variantpathclass > 2 AND variantpathclass < 6) -- Annoyingly, 6 corresponds to class 1/2...
OR  variantpathclass > 6)
AND codingdnasequencechange IS NOT NULL 
GROUP BY provider)
,
total_counts AS (
SELECT provider, COUNT(*) FROM (SELECT pseudo_id1, pseudo_id2, provider FROM restricted_results_all
WHERE genetictestscope LIKE 'Targeted%' OR
      genetictestscope LIKE 'AJ %' OR
      genetictestscope LIKE 'Polish%' 
GROUP BY pseudo_id1, pseudo_id2, provider) s1
GROUP BY provider
ORDER BY provider
)
SELECT tc.provider,
       --       round((CAST(vc.count AS float) / CAST(tc.count AS float))::numeric, 3),
       (CAST(vc.count AS float) / CAST(tc.count AS float))::numeric,
       vc.count AS var_count,
       tc.count AS total_count
FROM total_counts tc INNER JOIN var_counts vc
     ON tc.provider = vc.provider)
     
;

\COPY ( SELECT * FROM prov_counts_targeted ) TO 'output/prov_counts_targeted.csv' WITH csv header delimiter ','; 

----------------------------------------------------------------------------------
-- Identify AND extract cases WHERE the same mutations IS listed AS occuring IN --
-- MORE THAN one gene                                                           --
----------------------------------------------------------------------------------

CREATE temp TABLE problem_dna ON COMMIT DROP AS (
WITH problems AS (SELECT dna FROM results_table
GROUP BY dna HAVING COUNT(DISTINCT gene)>1)
SELECT dna, provider,        CASE WHEN gene::integer=7 THEN 'BRCA1'
            WHEN gene::integer=8 THEN 'BRCA2' END AS gene,
            raw_record FROM
problems ps INNER JOIN restricted_variants rv ON ps.dna = rv.codingdnasequencechange
ORDER BY dna, provider)
;

\COPY ( SELECT * FROM problem_dna ) TO 'output/problem_records.csv' WITH csv  delimiter ',' force quote raw_record,gene ; 

-----------------------------------------------------------------------
-- Count the NUMBER OF variants WITH an exon-level mutation recorded --
-----------------------------------------------------------------------
-- SELECT exonintroncodonnumber, gene, COUNT(*) FROM restricted_variants WHERE exonintroncodonnumber IS NOT NULL-- AND exonintroncodonnumber<>''

SELECT teststatus,COUNT(*) FROM restricted_results_all rr LEFT JOIN genetic_sequence_variants gsv
       ON rr.genetictestresultid = gsv.genetic_test_result_id
WHERE gsv.geneticsequencevariantid IS NULL
GROUP BY teststatus;
SELECT COUNT(*) FROM genetic_sequence_variants
;

SELECT * FROM prov_counts;
SELECT * FROM prov_counts_targeted;

WITH gr AS  
(SELECT pseudo_id1,
       pseudo_id2,
       provider
       --string_agg(DISTINCT provider, ',') AS prov
FROM restricted_results
WHERE gene IS NOT NULL 
GROUP BY pseudo_id1, pseudo_id2, provider HAVING COUNT(*)=1
)
SELECT provider, COUNT(*) FROM gr GROUP BY provider;
SELECT * FROM header_summary;

WITH apple AS (
SELECT pseudo_id1, pseudo_id2 FROM
(       molecular_data md INNER JOIN genetic_test_results gtr
       ON md.molecular_dataid = gtr.molecular_data_id
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id)
WHERE provider='RR8' AND genetictestscope LIKE 'Full%' AND concat(pseudo_id1, pseudo_id2) NOT IN (SELECT concat(id1, id2) FROM overlap_ids)
GROUP BY pseudo_id1, pseudo_id2)
SELECT COUNT(*) FROM apple;


CREATE temp TABLE mismatch ON COMMIT DROP AS (
WITH everyone AS (SELECT pseudo_id1 AS id1, pseudo_id2 AS id2, genetictestscope AS tscope, provider, servicereportidentifier, original_filename, md.raw_record AS raw_record   FROM 
(       molecular_data md INNER JOIN genetic_test_results gtr
       ON md.molecular_dataid = gtr.molecular_data_id
       INNER JOIN ppatients pp ON pp.id = md.ppatient_id
       INNER JOIN e_batch   eb ON eb.e_batchid = pp.e_batch_id)

),
potato AS (
SELECT oi.id1 AS id1,
       oi.id2 AS id2,
       rr8.tscope AS tscope_1,
       rr8.servicereportidentifier AS sri_1,
       rtd.tscope AS tscope_2,
       rtd.servicereportidentifier AS sri_2,
       rr8.raw_record AS rr1,
       rtd.raw_record AS rr2 FROM (
       overlap_ids oi INNER JOIN (
       SELECT * FROM everyone WHERE provider='RR8' ) rr8 ON oi.id1 = rr8.id1 AND oi.id2 = rr8.id2
       INNER JOIN (
      Select * FROM everyone WHERE provider='RTD' ) rtd ON oi.id1 = rtd.id1 AND oi.id2 = rtd.id2

)
WHERE NOT rr8.tscope = rtd.tscope)
SELECT id1, id2, sri_1, sri_2, rr1, rr2  FROM potato
GROUP BY id1, id2, sri_1, sri_2, rr1, rr2);
\COPY ( SELECT * FROM mismatch ) TO 'output/mismatch_records.csv' WITH csv  delimiter ',' ; 
SELECT COUNT(*) FROM genetic_sequence_variants WHERE variantpathclass=3;

--SELECT rvj FROM center_counts_by_change;
SELECT SUM(count) FROM center_counts WHERE provider='RNZ';
SELECT SUM(rtd) FROM results_table;
-- SELECT SUM(rvj) FROM center_counts_by_change;
-- SELECT COUNT(*) FROM restricted_variants WHERE provider='RVJ' and codingdnasequencechange IS NOT NULL
--        AND gene IS NOT NULL
--        AND genetictestscope LIKE 'Full%';
CREATE temp TABLE leeds_targeted ON COMMIT DROP AS  (
SELECT
raw_record
--pseudo_id1, pseudo_id2
FROM restricted_variants
WHERE provider='RR8'
AND (genetictestscope LIKE 'Targ%'
OR genetictestscope LIKE 'AJ %'
OR genetictestscope LIKE 'Polish%')
AND codingdnasequencechange IS NOT NULL
AND gene IS NOT NULL 
--GROUP BY molecular_dataid
);
\COPY ( SELECT * FROM leeds_targeted ) TO 'output/leeds_targeted.csv' WITH csv  delimiter ',' ; 
--GROUP BY pseudo_id1, pseudo_id2;
-- SELECT
-- pseudo_id1
-- --pseudo_id1, pseudo_id2
-- FROM restricted_variants
-- WHERE provider='RR8'
-- AND (genetictestscope LIKE 'Targ%'
-- OR genetictestscope LIKE 'AJ %'
-- OR genetictestscope LIKE 'Polish%')
-- AND codingdnasequencechange IS NOT NULL
-- AND gene IS NOT NULL ;



------------------------------------------------------------------
-- Produce the TABLE comparing how different providers classify --
-- variant pathogenicity (WITHOUT counts)                       --
------------------------------------------------------------------
CREATE temp TABLE mutations_path_class ON COMMIT DROP AS (
SELECT provider,
       --rr.gene,
       gene,
       codingdnasequencechange,
       --string_agg(DISTINCT variantpathclass::text, ',') AS pathclass
       AVG(variantpathclass) AS pathclass
       FROM 
    --   (restricted_results rr INNER JOIN genetic_sequence_variants gsv
    --   ON rr.genetictestresultid = gsv.genetic_test_result_id)
       restricted_variants
       WHERE codingdnasequencechange IS NOT NULL
       AND gene IS NOT NULL
       --AND genetictestscope LIKE 'Full%'
       GROUP BY codingdnasequencechange, gene, provider
       );


CREATE temp TABLE mutation_class_by_center ON COMMIT DROP AS      
(SELECT
        codingdnasequencechange,
   	   CASE WHEN ls.gene::integer=358 THEN 'APC'
   	   WHEN ls.gene::integer=577 THEN 'BMPR1A'
   	   WHEN ls.gene::integer=1432 THEN 'EPCAM'
   	   WHEN ls.gene::integer=2744 THEN 'MLH1'
   	   WHEN ls.gene::integer=2804 THEN 'MSH2'
   	   WHEN ls.gene::integer=2808 THEN 'MSH6'
   	   WHEN ls.gene::integer=2850 THEN 'MUTYH'
   	   WHEN ls.gene::integer=3394 THEN 'PMS2'
   	   WHEN ls.gene::integer=3408 THEN 'POLD1'
   	   WHEN ls.gene::integer=5000 THEN 'POLE'
   	   WHEN ls.gene::integer=62 THEN 'PTEN'
   	   WHEN ls.gene::integer=72 THEN 'SMAD4'
   	   WHEN ls.gene::integer=76 THEN 'STK11'
   	   WHEN ls.gene::integer=1882 THEN 'GREM1'
   	   WHEN ls.gene::integer=3108 THEN 'NTHL1'
	     END AS gene,
       AVG(CASE WHEN provider='RQ3' THEN count END)::integer AS RQ3,
       AVG(CASE WHEN provider='RNZ' THEN count END)::integer AS RNZ,
       AVG(CASE WHEN provider='RGT' THEN count END)::integer AS RGT,
       AVG(CASE WHEN provider='R1K' THEN count END)::integer AS R1K,
       AVG(CASE WHEN provider='RR8' THEN count END)::integer AS RR8,
       AVG(CASE WHEN provider='RTD-RR8' THEN count END)::integer AS RTD_RR8,
       AVG(CASE WHEN provider='R0A' THEN count END)::integer AS RA0,
       AVG(CASE WHEN provider='RTD' THEN count END)::integer AS RTD,
       AVG(CASE WHEN provider='RX1' THEN count END)::integer AS RX1,
       AVG(CASE WHEN provider='RNZ' THEN count END)::integer AS RNZ,
       AVG(CASE WHEN provider='RCU' THEN count END)::integer AS RCU,
       AVG(CASE WHEN provider='RPY' THEN count END)::integer AS RPY,
       AVG(CASE WHEN provider='RP4' THEN count END)::integer AS RP4,
       AVG(CASE WHEN provider='RTH' THEN count END)::integer AS RTH
FROM mutations_path_class
GROUP BY codingdnasequencechange, gene
ORDER BY codingdnasequencechange, gene);

--SELECT * FROM mutation_class_by_center;
\COPY ( SELECT * FROM mutation_class_by_center ) TO 'output/mutation_class_by_center.csv' WITH csv header delimiter ',' ; 

SELECT age FROM genetic_sequence_variants; 

COMMIT;
