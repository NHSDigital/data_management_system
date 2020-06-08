#!/bin/bash

read -rsp "Enter repseudonymsation salt: " salt_repseudo; echo
SRC="$1" # Has columns PSEUDO_ID,Patient_NHS_Number,Patient_Date_Of_Birth,n
DEST="$2"
ruby repseudo/ndr_repseudonymise.rb \
     <(sed -e '1s/^PSEUDO_ID,/pseudo_id1,/' "$SRC") \
     "$DEST" "$salt_repseudo" || (
    echo Failed - removing incomplete output file
    rm -f "$DEST"
)
