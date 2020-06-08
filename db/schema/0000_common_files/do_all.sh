#!/bin/bash

read -rp 'Enter DB, e.g. testdb: ' DB
read -rp 'Enter DBA, e.g. dbakelvinhunter: ' DBA
read -p 'Enter PGPASSWORD: ' -s PGPASSWORD
echo
export DB DBA PGPASSWORD

./fix_prescr_sequences.sh
./disable_prescr_indexes.sh drop

y="2015"
for m in 4 5 6 7; do
   echo "Processing $y $m part a"
   ./create_prescr.py $y $m a
   chmod 644 *.csv
   ./load_tables.sh $y $m a
   echo "Processing $y $m part b"
   ./create_prescr.py $y $m b
   chmod 644 *.csv
   ./load_tables.sh $y $m b
done
echo "Recreating indexes"
./disable_prescr_indexes.sh recreate
