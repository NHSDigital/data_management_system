
with singles as (select mdid from (
select pseudo_id1, pseudo_id2, string_agg(distinct molecular_dataid::text,',') as mdid,count(*) from
(
(select * from genetic_test_results) gtr inner join
(select * from molecular_data)       md
        on gtr.molecular_data_id = md.molecular_dataid
inner join
(select * from ppatients) pps on pps.id = md.ppatient_id
inner join
(select * from e_batch) eb    on eb.e_batchid = pps.e_batch_id

)
where provider = 'RVJ' and
genetictestscope like 'Full%'
group by pseudo_id1, pseudo_id2 having count(*) < 2
order by count) s1
--limit 2
)
select provider, count(*) from (
(select * from molecular_data) md inner join
(select * from ppatients) pps on pps.id = md.ppatient_id
inner join
(select * from e_batch) eb    on eb.e_batchid = pps.e_batch_id
)
where servicereportidentifier is null
group by provider
limit 3000
;
