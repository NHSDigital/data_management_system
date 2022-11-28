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


RR8_2 () {
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH  -type f  -name "*other*pseudo" -path "*/$PROV/*" )
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

RX1_2 () {
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*Bowel*.pseudo" -path "*/$PROV/*" )
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
bundle exec rake import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RGT () {
PROV='RGT'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*Lynch*.pseudo" -path "*/$PROV/*" )
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

RTH () {
PROV='RTH'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3 () {
PROV='RQ3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -iname "*Colon*.pseudo"  -o -type f -iname "*Colorectal*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

REP () {
PROV='REP'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
bundle exec rake import:colorectal fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RR8; RR8_2; RNZ; RTD; RX1; RCU; RGT; R0A; R1K; RX1_2; RPY; RP4; RTH; RQ3; REP
