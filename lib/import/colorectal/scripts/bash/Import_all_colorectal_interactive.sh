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
#db_cycle
OIFS="$IFS"
IFS=$'\n'
DIRPATH=$1
echo $DIRPATH
#DIRPATH=~/work/data_management_system
#FILEPATH="private/pseudonymised_data/updated_files/"
FILEPATH=$2
echo $FILEPATH

RTD () {
PROV='RTD'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*Colorectal*pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8 () {
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH  -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*MMR*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RR8_2 () {
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*"  -type f  -name "*other*pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RNZ () {
PROV='RNZ'
IFS=$'\n'
for x in $(find $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RX1 () {
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" -o -type f -name "*Bowel*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
PROV='RCU'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
bundle exec rake import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RGT () {
PROV='RGT'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R0A () {
PROV='R0A'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -iname "*HNPCC*.pseudo" -path "*/$PROV/*" -o -type f -iname "*FAP*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R1K () {
PROV='R1K'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RPY () {
PROV='RPY'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RP4 () {
PROV='RP4'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*CRC*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RTH () {
PROV='RTH'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3 () {
PROV='RQ3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -iname "*Colon*.pseudo"  -o -type f -iname "*Colorectal*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

REP () {
PROV='REP'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R1H () {
PROV='R1H'	
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -not -path "*/API_BETA_RETRIEVED/*" -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2021/*" \
)
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}



RJ7 () {
PROV='RJ7'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH  -type f -iname "*CRC*.pseudo" -path "*/$PROV/*" -o -type f -iname "*colorectal*.pseudo"  -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8; RR8_2; RNZ; RTD; RX1; RCU; RGT; R0A; R1K; RPY; RP4; RTH; RQ3; REP; R1H; RJ7




