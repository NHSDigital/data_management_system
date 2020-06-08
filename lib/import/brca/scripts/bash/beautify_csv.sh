# Applies the pretty csv creator to all files in the specified directory matching
# the 3-character providercode passed in as the first paramater
DATA_DIR=~/work/mbis2_again/private/pseudonymised_data/updated_files/
BRCA_HOME=~/work/mbis2_again/lib/import/brca
find $DATA_DIR \
     -type f -wholename "*/$1/*.pseudo" \
     -exec bundle exec ruby -I $BRCA_HOME $BRCA_HOME/utility/pseudonymised_file_converter.rb {} \;

