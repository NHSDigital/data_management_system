#!/bin/bash
# Tests and optionally fixes prescription sequences, if they're out of sync for
# the create_prescr.sh script

if [ -z "$DB" -o -z "$DBA" ] ; then
    echo Error: expected environment variables DB and DBA to be defined
    exit 1
fi

function fix_sequence {
    FIELD="$1"
    TABLE="$2"
    SEQUENCE="$3"
    if [ -z "$FIELD" -o -z "$TABLE" -o -z "$SEQUENCE" ] ; then
        echo Error: expected arguments for field, table and sequence respectively
        exit 1
    fi
    echo $FIELD
    echo $TABLE
    echo $SEQUENCE
    psql -q $DB -U $DBA <<SQL
      BEGIN;
      -- protect against concurrent inserts while you update the counter
      LOCK TABLE $TABLE IN EXCLUSIVE MODE;
      -- Check the current sequence value
      SELECT nextval('$SEQUENCE');
      -- Update the sequence
      SELECT setval('$SEQUENCE', COALESCE((SELECT MAX($FIELD)+1 FROM $TABLE), 1), false);
      COMMIT;
SQL
}

fix_sequence id ppatients ppatients_id_seq
fix_sequence ppatient_rawdataid ppatient_rawdata ppatient_rawdata_ppatient_rawdataid_seq
fix_sequence e_batchid e_batch e_batch_e_batchid_seq
