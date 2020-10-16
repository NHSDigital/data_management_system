#!/bin/bash
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
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*Colorectal*pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8 () {
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*MMR*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RNZ () {
PROV='RNZ'
IFS=$'\n'
for x in $(find $DIRPATH/$FILEPATH -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RX1 () {
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
PROV='RCU'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RGT () {
PROV='RGT'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
 -name "fea859a7be837b797e84999e67f8fbe5397dfcff_12.2019_Lynch data 2009 to 2019 for checking.csv.pseudo")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R0A () {
PROV='R0A'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*HNPCC*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R1K () {
PROV='R1K'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RPY () {
PROV='RPY'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RP4 () {
PROV='RP4'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*CRC*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8; RNZ; RTD; RX1; RCU; RGT; R0A; R1K; RPY; RP4
