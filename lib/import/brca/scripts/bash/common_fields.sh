# Pass in a 3-character provider code as the first parameter
#
# For the specified data directory, identify which fields are present in all the
# files for the specified provider, and group files by the fields which are unique to them

BRCA_HOME=/home/nathan/mbis/lib/import/brca
DATA_DIR=/media/sf_vm_shared/pseudonymised/

find $DATA_DIR \
     -type f -wholename "*/$1/*.pseudo" \
    | bundle exec ruby -I $BRCA_HOME $BRCA_HOME/utility/pseudonymised_file_converter.rb -c
