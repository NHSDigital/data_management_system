create or replace view public.v_ppatients_prescriptions
as
select *
from public.t1m_ppatients
where type = 'Pseudo::Prescription'
;

create or replace view public.v_ppatient_rawdata
  ( ppatient_rawdataid
  , rawdata
  )
as
select
    ppatient_rawdataid
  , rawdata
from public.t1m_ppatient_rawdata
;

create role lvanalysisuseranon nologin;
create role prescriptionsuseranon nologin;

grant lvanalysisuseranon to prescriptionsuseranon;

grant select on public.v_ppatients_prescriptions to prescriptionsuseranon;
grant select on public.v_ppatient_rawdata to prescriptionsuseranon;
grant select on public.t1m_prescription_data to prescriptionsuseranon;
revoke select on public.prescription_data from prescriptionsuseranon;

-- Generate lookup table grants
-- select 'grant select on public.'||tablename||' to lvanalysisuseranon;'
-- from pg_tables
-- where schemaname = 'public'
-- and tablename like 'z%';

--Be picky about which we grant (according to Kelvin's feedback
--grant select on public.z_project_statuses to lvanalysisuseranon;
--grant select on public.z_team_statuses to lvanalysisuseranon;
--grant select on public.z_user_statuses to lvanalysisuseranon;
grant select on public.ze_actiontype to lvanalysisuseranon;
grant select on public.ze_type to lvanalysisuseranon;
grant select on public.zprovider to lvanalysisuseranon;
grant select on public.zuser to lvanalysisuseranon;

grant select on public.e_batch to lvanalysisuseranon;
