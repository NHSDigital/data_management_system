#!/bin/bash

if [ -z "$EXPORT_KLASS"]; then
    read -rp "Enter EXPORT_KLASS, e.g. Export::ViralHepatitisDeathsFile3: " EXPORT_KLASS
    export EXPORT_KLASS
fi

# NHS_SUFFIX=_nhs # Only records with NHS numbers
# NHS_SUFFIX='' # All records, with / without NHS numbers
if [ -z "$NHS_SUFFIX"]; then
    read -rp "Enter NHS_SUFFIX (blank for all records, _nhs for NHS numbered only): " NHS_SUFFIX
    export NHS_SUFFIX
fi

# Prompt for MBIS_KEK
if [ -z "$MBIS_KEK" ]; then
    read -rsp 'MBIS_KEK: ' MBIS_KEK; echo
    export MBIS_KEK
fi

YEAR=2019
ROLLUP_FILE=""
# ROLLUP_FILE="deaths/MBIS_DEATHS_2018_REFRESH_20190118.txt"O
OUTFILE=${YEAR}_provisional_deaths.csv
TMPFILE=${YEAR}_death_tmp.csv

if [ -z "$ROLLUP_FILE" ]; then
    # No roll-up file actually required for 2019 deaths, just using the weekly files
    rm -f private/mbis_data/extracts/"$OUTFILE"
else
    echo "$ROLLUP_FILE" | \
        while read BASE; do
            echo Exporting $BASE:
            bundle exec rake export:death fname="$OUTFILE" original_filename="$BASE" klass="$EXPORT_KLASS" filter=all$NHS_SUFFIX RAILS_ENV=production
            cp -p private/mbis_data/extracts/"$OUTFILE" private/mbis_data/extracts/"$OUTFILE".orig
        done
fi

bundle exec rails runner -e production 'puts EBatch.where(e_type: "PSDEATH").order(:e_batchid).pluck(:original_filename).select{|s|s =~ /^deaths\/MBISWEEKLY_Deaths_D(19[0-9][0-9]|2001)[0-9]{2}.txt$/}' | \
while read BASE; do
  echo Exporting $BASE:
  bundle exec rake export:death fname="$TMPFILE" original_filename="$BASE" klass="$EXPORT_KLASS" filter=new$NHS_SUFFIX RAILS_ENV=production
	if [ ! -e private/mbis_data/extracts/"$OUTFILE" ]; then
			# Create header row, if no roll-up file available
			head -1 private/mbis_data/extracts/"$TMPFILE" > private/mbis_data/extracts/"$OUTFILE"
	fi
	tail -n+2 private/mbis_data/extracts/"$TMPFILE" >> private/mbis_data/extracts/"$OUTFILE"
  mv private/mbis_data/extracts/"$TMPFILE" `mktemp private/mbis_data/extracts/${YEAR}_death_testing.XXXXX`
done
# Minimalist ruby-based csvcut, based on DOR in ${YEAR}
lib/export/scripts/csvcut_dor.sh DOR ${YEAR} < private/mbis_data/extracts/"$OUTFILE" > private/mbis_data/extracts/${YEAR}_provisional_deaths_DOR${YEAR}.csv
echo Done
