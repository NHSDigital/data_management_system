#!/bin/bash

echo Extracts all birth and death data up to 2022:

# Go to the base directory of the MBIS project, wherever the script it run from.
cd "`dirname "$0"`/../../.."

if [ -z "$MBIS_KEK_USERNAME" ] ; then
  echo "MBIS_KEK_USERNAME options: " \
  `(cd config/keys; ls *_mbis.kek | sed -e 's/_mbis[.]kek$//')`
  read -rp "Enter MBIS_KEK_USERNAME: " MBIS_KEK_USERNAME; export MBIS_KEK_USERNAME
  unset MBIS_KEK
fi

if [ -z "$MBIS_KEK" ] ; then
  read -rsp "Enter MBIS_KEK passphrase: " MBIS_KEK; echo; export MBIS_KEK
fi

DEST_DIR=private/mbis_data/extracts/

# bin/rails runner -e production "puts EBatch.where(e_type: 'PSDEATH').where('original_filename like ?', 'deaths/MBISWEEKLY_Deaths_D${NEXT_YEAR_YY}%').order(:e_batchid).pluck(:original_filename)" | \
bin/rails runner -e production "puts EBatch.where(e_type: 'PSDEATH').order(:e_batchid).pluck(:original_filename)" | \
while read BASE; do
  BASE7Z="${BASE%.txt}.7z"
  if [ -e "$DEST_DIR/$BASE7Z" ]; then
    echo Skipping already exported $BASE
  else
    echo Exporting $BASE:
    bin/rake export:death fname="$BASE" original_filename="$BASE" klass=Export::DelimitedFile RAILS_ENV=production
    if [ -e "$DEST_DIR/$BASE" ]; then
      (cd "$DEST_DIR"; 7za a "$BASE7Z" "$BASE" -sdel)
    else
      echo Error: no extracted file $BASE
    fi
  fi
done

# Code copied and pasted from above, but replacing PSDEATH with PSBIRTH and death with birth
# bin/rails runner -e production "puts EBatch.where(e_type: 'PSBIRTH').where('original_filename like ?', 'births/MBISWEEKLY_Births_B${NEXT_YEAR_YY}%').order(:e_batchid).pluck(:original_filename)" | \
bin/rails runner -e production "puts EBatch.where(e_type: 'PSBIRTH').order(:e_batchid).pluck(:original_filename)" | \
while read BASE; do
  BASE7Z="${BASE%.txt}.7z"
  if [ -e "$DEST_DIR/$BASE7Z" ]; then
    echo Skipping already exported $BASE
  else
    echo Exporting $BASE:
    bin/rake export:birth fname="$BASE" original_filename="$BASE" klass=Export::DelimitedFile RAILS_ENV=production
    if [ -e "$DEST_DIR/$BASE" ]; then
      (cd "$DEST_DIR"; 7za a "$BASE7Z" "$BASE" -sdel)
    else
      echo Error: no extracted file $BASE
    fi
  fi
done

(cd "$DEST_DIR/deaths"
 for fn in 'Received 2018-04-30'/*; do mv -v "$fn" "`echo "$fn"|tr "/ " '_'`";done
 rmdir 'Received 2018-04-30'
)

echo TODO: Run schema dump commands (see this script file for details)
# $ E_TYPE=PSDEATH DEST=death_file_format.csv rails runner -e production "recs = Export::DelimitedFile.new(nil, ENV['E_TYPE'], nil).data_schema; CSV.open(ENV['DEST'], 'w', headers: recs.first.keys, write_headers: true) { |csv| recs.each { |rec| csv << rec } }"
# $ E_TYPE=PSBIRTH DEST=birth_file_format.csv rails runner -e production "recs = Export::DelimitedFile.new(nil, ENV['E_TYPE'], nil).data_schema; CSV.open(ENV['DEST'], 'w', headers: recs.first.keys, write_headers: true) { |csv| recs.each { |rec| csv << rec } }"


echo Done
