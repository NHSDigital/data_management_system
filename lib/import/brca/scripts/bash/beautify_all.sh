#!/bin/bash
# Create excel-readable csv files from ALL .pseudo files in the specified location. Readable
# files are created new; no modification of the .pseudo files themselves occurs
# Set BRCA_HOME to where the BRCA code lives, and DATA_DIR to where
# the .pseudo SVN has been checked out

BRCA_HOME=/home/nathan/mbis/lib/import/brca
DATA_DIR=/media/sf_vm_shared/pseudonymised/

find $DATA_DIR -type f \
     -wholename "*.pseudo" \
     -exec bundle exec ruby -I $BRCA_HOME $BRCA_HOME/utility/pseudonymised_file_converter.rb {} \;


