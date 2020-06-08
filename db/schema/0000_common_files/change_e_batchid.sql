-- One-off usage:
--   Due to a Rails issue, e_batchid wasn't initially created as a sequence;
--   change its definition here if you need to do it on-the-fly.

CREATE SEQUENCE e_batch_e_batchid_seq
  INCREMENT 1
  MINVALUE 1
  NO MAXVALUE
  START 1
  CACHE 1;

ALTER TABLE e_batch ALTER COLUMN e_batchid SET NOT NULL;

ALTER TABLE e_batch ALTER COLUMN e_batchid
  SET DEFAULT nextval('e_batch_e_batchid_seq'::regclass);

CREATE INDEX ON e_batch (e_batchid);
