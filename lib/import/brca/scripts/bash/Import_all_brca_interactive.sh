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

RVJ () {
echo $DIRPATH/$FILEPATH 
PROV='RVJ'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
-not -path "*/2017-05-09/*" \
-not -path "*/2017-06-15/*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RTD () {
echo $DIRPATH/$FILEPATH
PROV='RTD'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2017/*" \
! -name "*Colorectal*" \
! -name "*Other*" \
! -name "*other*" \
! -name "*CAPP2*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8 () {
MBIS=$1
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
-not -path "*/2017-03-17/*" \
  ! -name "3a4d3dc703789864fa6d2b8f5d9fe60749205979_01.01.2013 to 30.09.2018_010113_300918.xlsx.pseudo" \
  ! -name "*MMR*" \
  ! -name "*Colorectal*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RNZ () {
MBIS=$1
PROV='RNZ'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2018-02-06/*" \
! -name "*Lynch*" \
! -name "*PTEN*"  )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RX1 () {
MBIS=$1
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" -not -path "*/2017-06-14/*" \
! -name "*Lynch*" \
! -name "*Bowel*" \
! -name "*Endo*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
PROV='RCU'
IFS=$'\n'
for x in $(find $DIRPATH/$FILEPATH -type f -path "*/$PROV/*" \
\( -iname "*BRCA*.pseudo" -o -iname "*HBOC*.pseudo" -o \
	-name "*1dbb561a296d1efcf685bd67a3b*pseudo" \)  \
! -iname "*NON_CRC_HBOC_*" \
! -iname "*lynch*" \
! -iname "*nonBRCA*" \
! -iname "*Colorectal*" \
! -iname "*Hereditary Cancer_Other*" )
do
  if echo "$x" | grep -q "576f0670b0490bc788f673a5653c28cc1f7e7f7" || ! echo "$x" | grep -q "CRC"; then
	IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
  fi
done
}

RQ3 () {
PROV='RQ3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2018-02-06/*" \
! -name "*Rare*" \
! -name "*Colon*" \
! -name "*COLON*" \
! -name "*non BRCA*" \
! -name "*bwnft*"  )
  do
  IFS="$OIFS"
  $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
  done
  }


RJ1 () {
MBIS=$1
PROV='RJ1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name ""Dummy_Pseudo_RJ1.pseudo)
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RGT () {
MBIS=$1
PROV='RGT'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
  ! -name "*Lynch*" \
  ! -name "*mlpa_test*" \
  ! -name "*dummy*")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


R0A () {
MBIS=$1
PROV='R0A'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" ! -name "*HNPCC*" ! -name "*FAP*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RPY () {
MBIS=$1
PROV='RPY'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "8f98012da7c87b12ca1221dd3dc9d34a10952720_05.2019_BRCA only TGL data_cleaned2.xlsx.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

#to handle the new file format
RJ7 () {
MBIS=$1
PROV='RJ7'
IFS=$'\n'
for x in $(find $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" -name "*HBOC*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

#to handle the old file format
RJ7_2 () {
MBIS=$1
PROV='RJ7'
PROV_OLD_FILE='RJ7_2'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2021/*" \
-not -path "*/2022/*" \
-not -path "*/2023/*" \
! -name "c466c80823235315f4df98bb4a14c4937ee5cbc4_08.2020_STG HBOC PHE reported till 28082020.xlsx.pseudo" \
! -name "*HBOC*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV_OLD_FILE
done
}

RTH () {
MBIS=$1
PROV='RTH'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R1K () {
MBIS=$1
PROV='R1K'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*BRCA*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RP4 () {
MBIS=$1
PROV='RP4'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*BRCA*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

REP () {
echo $DIRPATH/$FILEPATH 
PROV='REP'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RTD; RQ3; RR8; RNZ; RVJ; RX1; RCU; RJ1; RGT; RPY; R0A; RJ7; RJ7_2 ; RTH; R1K; RP4; REP


