#!/bin/bash
BRAKE='bundle exec rake'
#db_cycle
OIFS="$IFS"
IFS=$'\n'
DIRPATH=$1
echo $DIRPATH
#DIRPATH=~/work/dms
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
  ! -name *MMR* \
  ! -name *other* \
  ! -name *Colorectal*)
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
for x in $(find $DIRPATH/$FILEPATH -type f \
\( -name "*BRCA*.pseudo*" -o \
-name "143e91983941d5040b176a997b80509b43bc686d_01.12.2019*pseudo" \
-o -name "*1dbb*pseudo" \
-o -name "0341fb*pseudo" \) -path "*/$PROV/*" \
! -name "*Colorectal*" \
! -name "*NonBRCA*" \
! -name "*nonBRCA*")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
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
! -name "*TRIP13*" \
! -name "8f98012da7c87b12ca1221dd3dc9d34a10952720_05.2019_BRCA only TGL data_cleaned2.xlsx.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RJ7 () {
MBIS=$1
PROV='RJ7'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2021/*" \
! -name "c466c80823235315f4df98bb4a14c4937ee5cbc4_08.2020_STG HBOC PHE reported till 28082020.xlsx.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
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


RTD; RQ3; RR8; RNZ; RVJ; RX1; RCU; RJ1; RGT; RPY; R0A; RJ7; RTH; R1K; RP4; REP


