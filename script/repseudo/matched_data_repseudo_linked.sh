#!/bin/bash

if [ -z "$REPSEUDOSALT" ]; then
    read -rsp "Enter repseudonymisation salt: " REPSEUDOSALT; echo
fi
SRC="$1" # Has columns PSEUDO_ID,Patient_NHS_Number,Patient_Date_Of_Birth,n
DEST="$2"
DIRNAME="`dirname "$0"`" # Allow script to be run from a different directory
ruby "$DIRNAME"/ndr_repseudonymise.rb \
     <(sed -e '1s/^PSEUDO_ID,/pseudo_id1,/' "$SRC") \
     "$DEST" "$REPSEUDOSALT" || (
    echo Failed - removing incomplete output file
    rm -f "$DEST"
)
