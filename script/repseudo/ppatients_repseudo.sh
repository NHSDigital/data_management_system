#!/bin/bash

read -rsp "Enter repseudonymsation salt: " salt_repseudo; echo
mkdir -p orig
mv public.ppatients_linked.csv orig/
SRC="orig/public.ppatients_linked.csv"
DEST="public.ppatients_linked_repseudo.csv"
ruby ndr_repseudonymise.rb "$SRC" "$DEST" "$salt_repseudo" || (
		echo Failed - removing incomplete output file
    rm -f "$DEST"
)
