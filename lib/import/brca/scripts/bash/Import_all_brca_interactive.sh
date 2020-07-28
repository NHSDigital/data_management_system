#!/bin/bash
BRAKE='bundle exec rake'
#db_cycle
OIFS="$IFS"
IFS=$'\n'
DIRPATH=$1
echo $DIRPATH
#Dirpath was ~/work/mbis2_again
#Filepath was "private/pseudonymised_data/updated_files/"
FILEPATH=$2
echo $FILEPATH

RVJ () {
echo $DIRPATH/$FILEPATH 
PROV='RVJ'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
-not -path "*/2017-05-09/*"    \
-not -path "*/2017-06-15/*"  )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RTD () {
MBIS=$1
PROV='RTD'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*pseudo" -path "*/RTD/*" \
          | egrep -v ".*Colorectal.*pseudo|.*Other Cancers.*pseudo|.*Dummy.*pseudo|.*CAPP2.*pseudo")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8 () {
MBIS=$1
PROV='RR8'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
-not -path "*/2017-03-17/*" \
! -name "3a4d3dc703789864fa6d2b8f5d9fe60749205979_01.01.2013 to 30.09.2018_010113_300918.xlsx.pseudo" \
! -name "c658a0516d5e91acefc59ece77126c50b6a774cc_01.01.2006 to 31.03.2018_MMR gene 2006_31032018.xlsx.pseudo" \
! -name "cadc0b639036cbbce5a1bc51e630bde90e8d1ee0_01.10.2018 to 27.12.2019_other cancers 011018_271219.xlsx.pseudo" \
! -name "abb7505fa1c13e0d675e969d52f357002b560dab_01.04.2018 to 27.12.2019_MMR 010418_271219.xlsx.pseudo")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RNZ () {
MBIS=$1
PROV='RNZ'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2018-02-06/*" \
! -name "32b125df2fd306c7b2b6b7a6ec1362d368a02536_2017_Lynch full and predictives 2017.xlsx.pseudo" \
! -name "655e2321cd97be403ad7cf120b4132c52a26d79b_2018_Lynch full and predictives 2018.xlsx.pseudo" \
! -name "d47bfb9be436f0132fedb88be4a1685a02709fcf_2016_Lynch full and predictives 2016.xlsx.pseudo" \
! -name "ef6964b8789476f4e302b8ec199bd7718b1d101d_2019_Lynch full and predictives 2019.xlsx.pseudo" \
! -name "89d0d99aaccbcb34797c16015267c4cadbee61de_2015_Lynch full and predictives 2015.xlsx.pseudo" \
! -name "3a89d5a61f61b343adca31471ff39f8254226777_2019_PTEN full and predictives 2019.xlsx.pseudo" \
)
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RX1 () {
MBIS=$1
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" -not -path "*/2017-06-14/*" \
! -name "89201abfdac7685739944b5a6ea314065ec95d41_01.07.2018 to 01.12.2018_Lynch Challenge July2018_Dec2018v9.xlsx.pseudo" \
! -name "a67fbd953bb8a2df2b9b2ed793a74c6f4ab2efe5_01.01.2010 to 30.06.2018_Lynch Challenge Jan2010_June2018v19.xlsx.pseudo" \
! -name "c7005f8821f316a795e007bff866eaab5e1b0b0d_01.01.2019 to 30.11.2019_Lynch Challenge Jan2019_Nov2019v3.xlsx.pseudo" \
! -name "dc7887680a728a55cb0ae04d1209f963f3d9f429_12.2019_Lynch Challenge Dec2019v7.xlsx.pseudo")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
MBIS=$1
PROV='RCU'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "1acb5f31aa1f9d057b2105b9ac814c51f6f8bf44_01.04.2014 to 31.12.2018_Colorectal Cancer_09570820181212.csv.pseudo" \
! -name "723f1a253c120dfafe1439bf9150870cd0deda78_01.04.2014 to 01.12.2018_Historical_NonBRCA_NonColorectal_01042014-01122018.csv.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3 () {
MBIS=$1
PROV='RQ3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" )
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RJ1 () {
MBIS=$1
PROV='RJ1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"   )
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
! -name "fea859a7be837b797e84999e67f8fbe5397dfcff_12.2019_Lynch data 2009 to 2019 for checking.csv.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R0A () {
MBIS=$1
PROV='R0A'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "41cef5485574dddbb9704c4bc84973dde2fe2ca5_01.01.2007 to 31.12.2018_PHE HNPCC 2007-18.xls.pseudo" \
! -name "09cf085a0adc0df9a7c8c8ca4a894c0c242a2de6_12.2019_PHE HNPCC Extract_Dec19-Dec19.xls.pseudo" \
! -name "eb53bf3ca058b8bba047c4859985d78eb2fe99a1_01.01.2019 to 30.11.2019_PHE HNPCC Extract_Jan19-Nov19-mod.xls.pseudo" )
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RPY () {
MBIS=$1
PROV='RPY'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "8cd7b9ccf005413e8af99be1df07764b596751d3_12.2019_REST and TRIP13.xlsx.pseudo" \
! -name "440ae0dda3d4bdf26044aba95ee7ae4ea68241f7_12.2019_ready to submit TGL data only mainland uk with NHS numbers without BRCA_CORRECTED_wo_REST_TRIP13.xlsx.pseudo")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RJ7 () {
MBIS=$1
PROV='RJ7'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RTH () {
MBIS=$1
PROV='RTH'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

R1K () {
MBIS=$1
PROV='R1K'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*BRCA*.pseudo" -path "*/$PROV/*" \
! -name "d66a0bfbd7d994b76c7db3f5c38e2ea3e44118fc_01.2020_CRC2015_2016KGC.xlsx.pseudo")
do
IFS="$OIFS"
bundle exec rake import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RQ3; RR8; RNZ; RVJ; RTD; RX1; RCU; RJ1; RGT; RPY; R0A; RJ7; RTH; R1K
#RQ3
#RX1; RCU
#RTD
#RR8


