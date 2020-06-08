#!/bin/bash

DEST=create_prescr_indexes.sql
if [ $# != 1 ] ; then
    echo "Syntax: `basename "$0"` [drop|create]"
    echo "  Drop or recreate indexes for prescription data"
    echo "  drop - create a file of existing indexes $DEST, and drop them all"
    echo "  recreate - recreate indexes from $DEST"
    exit
fi

if [ -z "$DB" -o -z "$DBA" ] ; then
    echo Error: expected environment variables DB and DBA to be defined
    exit 1
fi

if [ "$1" = "drop" ] ; then
  if [ -e "$DEST" ] ; then
      DESTTMP=`mktemp $DEST.XXXX`
      mv "$DEST" "$DESTTMP"
  fi
  pg_dump $DB -U $DBA --section=post-data -t ppatients -t prescription_data | \
      grep 'CREATE INDEX ' > "$DEST"
  sed -Ee 's/CREATE INDEX ([^ ]*) ON [^;]*/DROP INDEX \1/' "$DEST" | psql -q $DB -U $DBA && \
      echo Indexes dropped
elif [ "$1" = "recreate" ] ; then
    psql -q $DB -U $DBA -f "$DEST" && echo Indexes recreated
else
    echo "Invalid argument '$1'"
    exit 1
fi
