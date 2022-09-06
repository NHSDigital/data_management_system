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
-not -path "*/2017-06-15/*"  )
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
for x in $(find  $DIRPATH/$FILEPATH  -type f  \( -name "a5a6c2470626d7c3b8e8e62380e30a02288a37f8_09.2020_BRCA Challenge AZOVCA 2015_2017.xlsx.pseudo" -o -name "9159d17e34ae13c12e8515f5ac930b49a3eb11a9_11.2020_BRCA Challenge BRCA to upload.xlsx.pseudo" \) -path "*/$PROV/*" )
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
! -name "45eab0f71c0fe071e320deea24d3ef89da0a4fe2_07.2016_mlpa_test.csv.pseudo" \
! -name "6c97b564b29711c02dbfb7d139cc6d4cbd6441e0_07.2016_mlpa_test.csv.pseudo" \
! -name "a6cb7307428d9895c2703300904e688eaa04e0e7_01.2013_brca_chal_dummy_171013.csv.pseudo" \
! -name "b7781fafea5cd1564e1270d69949643ff3d53323_01.2013_brca_chal_dummy.csv.pseudo" \
! -name "e9e4360b7b1cbd9e6d43fb15b9492b032af27b77_01.01.2009 to 31.10.2019_Lynch data 2009 to 2019 for checking no errors.csv.pseudo" \
! -name "fea859a7be837b797e84999e67f8fbe5397dfcff_12.2019_Lynch data 2009 to 2019 for checking.csv.pseudo" \
! -name "ea90909e3b33dc27f5e265bee8a583a56773cd29_01.08.2019 to 27.04.2020_Lynch_190801_200427_UPLOAD.csv.pseudo" )
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R0A () {
MBIS=$1
PROV='R0A'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "41cef5485574dddbb9704c4bc84973dde2fe2ca5_01.01.2007 to 31.12.2018_PHE HNPCC 2007-18.xls.pseudo" \
! -name "09cf085a0adc0df9a7c8c8ca4a894c0c242a2de6_12.2019_PHE HNPCC Extract_Dec19-Dec19.xls.pseudo" \
! -name "eb53bf3ca058b8bba047c4859985d78eb2fe99a1_01.01.2019 to 30.11.2019_PHE HNPCC Extract_Jan19-Nov19-mod.xls.pseudo")
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
! -name "8cd7b9ccf005413e8af99be1df07764b596751d3_12.2019_REST and TRIP13.xlsx.pseudo" \
! -name "440ae0dda3d4bdf26044aba95ee7ae4ea68241f7_12.2019_ready to submit TGL data only mainland uk with NHS numbers without BRCA_CORRECTED_wo_REST_TRIP13.xlsx.pseudo" \
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
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RTD; RQ3; RR8; RNZ; RVJ; RX1; RCU; RJ1; RGT; RPY; R0A; RJ7; RTH; R1K; RP4; REP


