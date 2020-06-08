-- *** one-off per database ***
-- needed to delay foreign-key constraint validation - until after transaction

-- get list of foreign keys
--  SELECT conname,tb.relname,pg_get_constraintdef(c.oid,true) FROM pg_constraint c
--  JOIN pg_class tb ON tb.oid = c.conrelid
--  JOIN pg_namespace ns ON ns.oid = tb.relnamespace
--  WHERE ns.nspname IN ('public') AND contype='f'
--  ORDER BY relname;

-- actual foreign key ids may be different

-- fk_rails_37572502ce | ppatients           | FOREIGN KEY (e_batch_id) REFERENCES e_batch(e_batchid)
-- fk_rails_973312a1aa | ppatients           | FOREIGN KEY (ppatient_rawdata_id) REFERENCES ppatient_rawdata(ppatient_rawdataid)
-- fk_rails_3dd8aff4eb | prescription_data   | FOREIGN KEY (ppatient_id) REFERENCES ppatients(id) ON DELETE CASCADE


ALTER TABLE ppatients DROP CONSTRAINT fk_rails_973312a1aa;
ALTER TABLE ppatients ADD CONSTRAINT fk_rails_973312a1aa
  FOREIGN KEY (ppatient_rawdata_id) REFERENCES ppatient_rawdata(ppatient_rawdataid)
  DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ppatients DROP CONSTRAINT fk_rails_37572502ce;
ALTER TABLE ppatients ADD CONSTRAINT fk_rails_37572502ce
  FOREIGN KEY (e_batch_id) REFERENCES e_batch(e_batchid)
  DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE prescription_data DROP CONSTRAINT fk_rails_3dd8aff4eb;
ALTER TABLE prescription_data ADD CONSTRAINT fk_rails_3dd8aff4eb
  FOREIGN KEY (ppatient_id) REFERENCES ppatients(id) ON DELETE CASCADE
  DEFERRABLE INITIALLY DEFERRED;
