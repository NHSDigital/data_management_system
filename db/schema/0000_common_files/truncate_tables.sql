-- ** for testing **

-- truncate tables 
TRUNCATE e_batch,ze_type,zprovider CASCADE; -- linkage management data
TRUNCATE ppatients,ppatient_rawdata CASCADE ; -- encrypted linkage data 
TRUNCATE birth_data, death_data, molecular_data, prescription_data CASCADE ; --linked data

-- reset primary key sequences
ALTER SEQUENCE ppatients_id_seq RESTART WITH 1;
ALTER SEQUENCE ppatient_rawdata_ppatient_rawdataid_seq RESTART WITH 1;

ALTER SEQUENCE e_batch_e_batchid_seq RESTART WITH 1;

ALTER SEQUENCE birth_data_birth_dataid_seq RESTART WITH 1;

ALTER SEQUENCE death_data_death_dataid_seq RESTART WITH 1;

ALTER SEQUENCE molecular_data_molecular_dataid_seq RESTART WITH 1;

ALTER SEQUENCE prescription_data_prescription_dataid_seq RESTART WITH 1;

--insert required values into lookup tables

-- 1. birth data 
DO
$body$
BEGIN
  IF NOT EXISTS (SELECT * FROM ze_type WHERE id = 'PSBIRTH') THEN
    INSERT INTO ze_type VALUES ('PSBIRTH');
  END IF;
  IF NOT EXISTS (SELECT * FROM zprovider WHERE zproviderid = 'XDC04') THEN
    INSERT INTO zprovider (zproviderid) VALUES ('XDC04') ;
  END IF;
END
$body$;

-- 2. death data 
DO
$body$
BEGIN
  IF NOT EXISTS (SELECT * FROM ze_type WHERE id = 'PSDEATH') THEN
    INSERT INTO ze_type VALUES ('PSDEATH');
  END IF;
  IF NOT EXISTS (SELECT * FROM zprovider WHERE zproviderid = 'XDC04') THEN
    INSERT INTO zprovider (zproviderid) VALUES ('XDC04') ;
  END IF;
END
$body$;

-- 3. prescription data 
DO
$body$
BEGIN
  IF NOT EXISTS (SELECT * FROM ze_type WHERE id = 'PSPRESCRIPTION') THEN
    INSERT INTO ze_type VALUES ('PSPRESCRIPTION');
  END IF;
  IF NOT EXISTS (SELECT * FROM zprovider WHERE zproviderid = 'Ti45Z') THEN
    INSERT INTO zprovider (zproviderid) VALUES ('T145Z') ;
  END IF;
  IF NOT EXISTS (SELECT * FROM zprovider WHERE zproviderid = 'X25') THEN
    INSERT INTO zprovider (zproviderid) VALUES ('X25') ;
  END IF;
END
$body$;

-- INSERT INTO ze_type VALUES ('PSPRESCRIPTION'),('PSDEATH'),('PSBIRTH') ;
-- INSERT INTO zprovider (zproviderid) VALUES ('T145Z'),('X25'),('XDC04') ;
