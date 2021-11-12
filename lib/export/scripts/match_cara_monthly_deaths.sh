#!/bin/bash

if [ -z "$CARA_ESOURCES_REPO" ]; then
    CARA_ESOURCES_REPO=https://localhost:4142/svn/cara-esources
    echo "Defaulting to CARA_ESOURCES_REPO=$CARA_ESOURCES_REPO"
fi

if [ ! -e private/mbis_data ]; then
    echo "ERROR: This script needs to be run from data_management_system home directory: aborting" >&2
    exit 1
fi

PREFIX="X25/BIRTH/live_trace_files"
INFILE=`svn ls -R "$CARA_ESOURCES_REPO/$PREFIX" | \
    egrep '^20[0-9]{2}-[0-9]{2}-[0-9]{2}/[0-9]*_birth_trace_file.csv'|sort -r|head -1`

if [ -z "$INFILE" ]; then
    echo ERROR: Cannot locate latest file from CARA_ESOURCES_REPO: aborting >&2
    exit 1
fi
INFILE="$PREFIX/$INFILE"
echo INFILE=$INFILE

BASEFILE="`basename "$INFILE"`"
RESPONSE="`basename "$BASEFILE" _birth_trace_file.csv`_birth_trace_response.csv"
echo RESPONSE=$RESPONSE

svn export --force "$CARA_ESOURCES_REPO/$INFILE" private/mbis_data/

echo Matching patients: this takes about 20 minutes for 2500 patients
bin/rake export:matched infile="$BASEFILE" outfile="$RESPONSE" allow_fuzzy=fuzzy e_type=PSBIRTH klass=Export::CongenitalAnomaliesBirthsFile RAILS_ENV=production
rm "private/mbis_data/$INFILE"

if [ ! -e "private/mbis_data/$RESPONSE" ]; then
    echo "ERROR: Missing output file private/mbis_data/$RESPONSE": aborting >&2
    exit 1
fi

TMPDIR=`mktemp -d private/cara-esources.XXXXXX`
svn checkout --depth=empty "$CARA_ESOURCES_REPO/X25/BIRTH" "$TMPDIR"
svn up --set-depth empty "$TMPDIR/`date +%Y`"
DEST="$TMPDIR/`date +%Y/%Y-%m-%d`"
svn up --set-depth empty "$DEST"
mkdir -vp "$DEST"

echo Moving response file to $TMPDIR, ready to commit:
mv private/mbis_data/"$RESPONSE" "$DEST"

echo -e "\nDestination file created. Distribution of years of birth:"
echo $RESPONSE
# csvcut -cDOB_ISO "$DEST/$RESPONSE" |tail -n+2|cut -c-4|sort|uniq -c
ruby -rcsv -e 'puts *CSV.read(ARGV[0], headers: true).collect { |row| row["DOB_ISO"] }' "$DEST/$RESPONSE" |cut -c-4|sort|uniq -c

svn add --parents "$DEST/$RESPONSE"
svn commit "$TMPDIR" -m "$(echo -e "CARA births matched data, for matches by NHS number to patients in\n$INFILE\nThis is for the birth records currently in MBIS as of `date +%Y-%m-%d`\nThe PATIENTID column is populated for linked birth records.")"

rm -rf "$TMPDIR"

echo Done
