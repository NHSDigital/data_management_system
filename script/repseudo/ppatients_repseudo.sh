#!/bin/bash

read -rsp "Enter repseudonymisation salt: " salt_repseudo; echo
mkdir -p orig
mv public.ppatients_linked.csv orig/
SRC="orig/public.ppatients_linked.csv"
DEST="public.ppatients_linked_repseudo.csv"
DIRNAME="`dirname "$0"`" # Allow script to be run from a different directory
ruby "$DIRNAME"/ndr_repseudonymise.rb "$SRC" "$DEST" "$salt_repseudo" || (
		echo Failed - removing incomplete output file
    rm -f "$DEST"
)
