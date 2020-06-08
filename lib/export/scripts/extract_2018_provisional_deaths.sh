#!/bin/bash

OUTFILE=2018_provisional_deaths.csv
EXPORT_KLASS=Export::ViralHepatitisDeathsFile3
TMPFILE=2018_death_tmp.csv
# NHS_SUFFIX=_nhs # Only records with NHS numbers
NHS_SUFFIX='' # All records, with / without NHS numbers

echo "deaths/MBIS_Deaths_2018 (1).txt" | \
while read BASE; do
  echo Exporting $BASE:
  bundle exec rake export:death fname="$OUTFILE" original_filename="$BASE" klass="$EXPORT_KLASS" filter=all$NHS_SUFFIX RAILS_ENV=production
  cp -p private/mbis_data/extracts/"$OUTFILE" private/mbis_data/extracts/"$OUTFILE".orig
done

echo "deaths/MBIS_Deaths_FROM LEDR 01012018_PROD.TXT
deaths/MBIS_20180209.txt
deaths/MBIS_20180216.txt
deaths/MBIS_20180223.txt
deaths/MBISWEEKLY_Deaths_D180303.txt
deaths/MBIS_20180302.txt
deaths/MBISWEEKLY_Deaths_D180310.txt
deaths/MBIS_20180312.txt
deaths/MBISWEEKLY_Deaths_D180317.txt
deaths/MBIS_20180319.txt
deaths/MBISWEEKLY_Deaths_D180326.txt
deaths/MBISWEEKLY_Deaths_D180404.txt
deaths/MBISWEEKLY_Deaths_D180407.txt
deaths/MBISWEEKLY_Deaths_D180414.txt
deaths/MBISWEEKLY_Deaths_D180421.txt
deaths/Received 2018-04-30/MBISWEEKLY_Deaths_D180407.txt
deaths/Received 2018-04-30/MBISWEEKLY_Deaths_D180414.txt
deaths/Received 2018-04-30/MBISWEEKLY_Deaths_D180421.txt
deaths/Received 2018-04-30/MBISWEEKLY_Deaths_D180428.txt
deaths/MBISWEEKLY_Deaths_D180505.txt
deaths/MBISWEEKLY_Deaths_D180512.txt
deaths/MBISWEEKLY_Deaths_D180519.txt
deaths/MBISWEEKLY_Deaths_D180526.txt
deaths/MBISWEEKLY_Deaths_D180602.txt
deaths/MBISWEEKLY_Deaths_D180609.txt
deaths/MBISWEEKLY_Deaths_D180616.txt
deaths/MBISWEEKLY_Deaths_D180623.txt
deaths/MBISWEEKLY_Deaths_D180630.txt
deaths/MBISWEEKLY_Deaths_D180707.txt
deaths/MBISWEEKLY_Deaths_D180714.txt
deaths/MBISWEEKLY_Deaths_D180721.txt
deaths/MBISWEEKLY_Deaths_D180728.txt
deaths/MBISWEEKLY_Deaths_D180804.txt
deaths/MBISWEEKLY_Deaths_D180811.txt
deaths/MBISWEEKLY_Deaths_D180820.txt
deaths/MBISWEEKLY_Deaths_D180827.txt
deaths/MBISWEEKLY_Deaths_D180903.txt
deaths/MBISWEEKLY_Deaths_D180910.txt
deaths/MBISWEEKLY_Deaths_D180917.txt
deaths/MBISWEEKLY_Deaths_D180924.txt
deaths/MBISWEEKLY_Deaths_D181001.txt
deaths/MBISWEEKLY_Deaths_D181008.txt
deaths/MBISWEEKLY_Deaths_D181015.txt
deaths/MBISWEEKLY_Deaths_D181022.txt
deaths/MBISWEEKLY_Deaths_D181029.txt
deaths/MBISWEEKLY_Deaths_D181105.txt
deaths/MBISWEEKLY_Deaths_D181112.txt
deaths/MBISWEEKLY_Deaths_D181119.txt
deaths/MBISWEEKLY_Deaths_D181126.txt
deaths/MBISWEEKLY_Deaths_D181203.txt
deaths/MBISWEEKLY_Deaths_D181210.txt
deaths/MBISWEEKLY_Deaths_D181217.txt
deaths/MBISWEEKLY_Deaths_D181224.txt
deaths/MBISWEEKLY_Deaths_D181231.txt
deaths/MBISWEEKLY_Deaths_D190107.txt
deaths/MBISWEEKLY_Deaths_D190114.txt
deaths/MBISWEEKLY_Deaths_D190121.txt
deaths/MBISWEEKLY_Deaths_D190128.txt
deaths/MBISWEEKLY_Deaths_D190204.txt
deaths/MBISWEEKLY_Deaths_D190211.txt
deaths/MBISWEEKLY_Deaths_D190218.txt
deaths/MBISWEEKLY_Deaths_D190225.txt
deaths/MBISWEEKLY_Deaths_D190304.txt
deaths/MBISWEEKLY_Deaths_D190311.txt
deaths/MBISWEEKLY_Deaths_D190318.txt
deaths/MBISWEEKLY_Deaths_D190325.txt" | \
while read BASE; do
  echo Exporting $BASE:
  bundle exec rake export:death fname="$TMPFILE" original_filename="$BASE" klass="$EXPORT_KLASS" filter=new$NHS_SUFFIX RAILS_ENV=production
  tail -n+2 private/mbis_data/extracts/"$TMPFILE" >> private/mbis_data/extracts/"$OUTFILE"
  mv private/mbis_data/extracts/"$TMPFILE" `mktemp private/mbis_data/extracts/2018_death_testing.XXXXX`
done
# Minimalist ruby-based csvcut, based on DOR in 2018
lib/export/scripts/csvcut_dor.sh DOR 2018 < 2018_provisional_deaths.csv > 2018_provisional_deaths_DOR2018.csv
echo Done
