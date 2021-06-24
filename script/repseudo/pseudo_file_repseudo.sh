#!/bin/bash
if [ $# = 0 ]; then
    echo Syntax: `basename "$0"` infile.pseudo outfile.csv
    echo Repseudonymise pseudo_id1 and pseudo_id2 from a .pseudo file
    exit 1
fi

SRC="$1"
DEST="$2"

# TODO: Support additional pseudonymised file formats

HEADER_v3="Pseudonymised matching data v3.0-EBaseRecord"
if [ "$HEADER_v3" != "`head -1 "$SRC"`" ]; then
    echo ERROR: Invalid .pseudo file "$SRC"
    echo Expected header row: "$HEADER_v3"
    echo Aborting
    exit 1
fi

read -rsp "Enter repseudonymsation salt: " salt_repseudo; echo
DIRNAME="`dirname "$0"`" # Allow script to be run from a different directory
ruby "$DIRNAME"/ndr_repseudonymise.rb \
     <(sed -e '1s/Pseudonymised matching data v3.0-EBaseRecord/pseudo_id1,pseudo_id2/' "$SRC" | \
       cut -d, -f1-2) \
     "$DEST" "$salt_repseudo" || (
    echo Failed - removing incomplete output file
    rm -f "$DEST"
)
