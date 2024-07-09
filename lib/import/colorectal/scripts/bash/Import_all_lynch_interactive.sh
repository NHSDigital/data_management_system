#!/bin/bash
if [ $# != 2 -o "$1" == "--help" ]; then
    CMD="`basename "$0"`"
    echo "Usage: $CMD DIRPATH FILEPATH"
    echo "  DIRPATH: the base directory of the data_management_system codebase"
    echo "  FILEPATH: the relative directory of the files to import"
    echo "Sample usage:"
    echo "$CMD ~/work/data_management_system private/pseudonymised_data/updated_files/"
    exit 1
fi

BRAKE='bundle exec rake'
OIFS="$IFS"
IFS=$'\n'
DIRPATH=$1
echo $DIRPATH
#DIRPATH=~/work/data_management_system
#FILEPATH="private/pseudonymised_data/updated_files/"
FILEPATH=$2
echo $FILEPATH

# These files of NHS England data for this run have been imported as Barts file in svn repository
X26_AD_HOC () {
PROV='R1H'
IFS=$'\n'
for x in $(find $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2021/*" \
)
do
IFS="$OIFS"
bundle exec rake import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code='X26'
done
}

X26_AD_HOC