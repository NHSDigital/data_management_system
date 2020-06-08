#!/bin/bash

# Run the SQL script to generate the summary table, then assemble the two components
#Change line 5 with current MBIS_HOME
MBIS_HOME=~/work/mbis
OUTPUT_LOC=$MBIS_HOME/lib/import/brca/scripts/sql/output/
pushd $MBIS_HOME/lib/import/brca/scripts/sql/
psql --dbname=mbis_development --file=full_screen_summary.sql \
     --output=$OUTPUT_LOC/table_generation_output.log
head -n 1 $OUTPUT_LOC/main_table.csv > $OUTPUT_LOC/summary_table.csv
tail -n +2 $OUTPUT_LOC/table_totals.csv >> $OUTPUT_LOC/summary_table.csv
tail -n +2 $OUTPUT_LOC/main_table.csv >> $OUTPUT_LOC/summary_table.csv
popd
