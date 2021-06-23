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
echo $DIRPATH/$FILEPATH 
PROV='RTD'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
-not -path "*/2017-05-11/*" \
-not -path "*/2017-08-02/*" \
-not -path "*/2017-12-04/*" \
 ! -name "c687591ef56698ec8dde11e2a7420caea0c6173c_09.2018_CAPP2 Pilot data upload.xlsx.pseudo" \
 ! -name "3268d1e4e28913926cc534d3b8658eca36907050_09.2018_CAPP2 Full Data Upload.xlsx.pseudo" \
 ! -name "a34f62c8499c20a48d5c5c228f5084f8f994e84c_10.2018_CAPP2 Full Data Upload.xlsx.pseudo" \
 ! -name "dda53265da69898d1e9725919a3a706c5003cd79_01.11.2006 to 30.06.2019_NUTH Colorectal Data - November 2006 to June 2019.xlsx.pseudo" \
 ! -name "1b2d27101d5a8ba9471d3e31ee60ad26964affb7_12.2019_NDR - Colorectal.xls.pseudo" \
 ! -name "0731b0a6b8087fa77e4488ea7cb0f4254864a4bb_12.2019_NDR - Other Cancers.xls.pseudo" \
 ! -name "b725d664af1bcce326a9433794e00243f36a5227_2019_NDR - Colorectal Cancer.xlsx.pseudo" \
 ! -name "ebe61e790a57c3d6d082754b0a1bf3d02323a0f8_01.10.2019 to 30.11.2019_NDR - Colorectal.xls.pseudo" \
 ! -name "fba361cdb4aaa08ee00ea7670956ca81b6242941_10.2020_Colorectal Gene Data.xlsx.pseudo" \
 ! -name "245c2c5c8f10bebb655228a94b756b94e07f8aa4_08.2020_Colorectal Cancer 01.08.2020 - 31.08.2020.xlsx.pseudo" \
 ! -name "2fa4bc9f31a6e0c6276156f935dc35065e4c2bd1_07.2019_NDR - Colorectal.xls.pseudo" \
 ! -name "a8e43ecadd553e06d8dce4631de725d50f6f85a0_08.2019_NDR - Colorectal.xls.pseudo" \
 ! -name "5590b86d6e705f08d93ceef477bb5c6b46e3d358_09.2019_NDR - Colorectal.xls.pseudo" \
 ! -name "bcc0938c18088b6b483e664c14bb1bb9b5248781_01.2020_NDR - Colorectal Cancer.xlsx.pseudo" \
 ! -name "fd047a2a4cf34f6e5aa4bbecdc8e08b012da42c5_02.2020_NDR - Colorectal.xls.pseudo" \
 ! -name "41ae35e88b2e9f2b41f1e1b22ea6a9a010ca7885_03.2020_NDR - Colorectal.xls.pseudo" \
 ! -name "8d6891c2dc52226ca77b301180d58ec22f10922d_05.2020_NDR - Colorectal.xlsx.pseudo" \
 ! -name "ab107f8ba21a6c823de18b62aab2b0f459f74d63_06.2020_Colorectal Gene Data.xlsx.pseudo" \
 ! -name "e869c9f6c1b96b2b1c4bad564978b827e44fa944_01.07.2019 to 31.07.2020_Colorectal Cancer 01.07.2019 - 31.07.2020.xlsx.pseudo" \
 ! -name "4bae180b69902c9618d214fb8867ca7be3afcf57_09.2020_Colorectal Data 01.09.2020 - 30.09.2020.xlsx.pseudo" \
 ! -name "3f879c487642bc77e25868e6caa7686e7c86770e_11.2020_Colorectal Gene Data.xlsx.pseudo" )
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
! -name "abb7505fa1c13e0d675e969d52f357002b560dab_01.04.2018 to 27.12.2019_MMR 010418_271219.xlsx.pseudo" \
! -name "41ae35e88b2e9f2b41f1e1b22ea6a9a010ca7885_03.2020_NDR - Colorectal.xls.pseudo" \
! -name "a8e43ecadd553e06d8dce4631de725d50f6f85a0_08.2019_NDR - Colorectal.xls.pseudo" \
! -name "0ca547381e5644e9bfafc86ed56ba317a5a00b84_28.12.2019 to 30.11.2020_MMR 281219_301120.xlsx.pseudo" )
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
! -name "32b125df2fd306c7b2b6b7a6ec1362d368a02536_2017_Lynch full and predictives 2017.xlsx.pseudo" \
! -name "655e2321cd97be403ad7cf120b4132c52a26d79b_2018_Lynch full and predictives 2018.xlsx.pseudo" \
! -name "d47bfb9be436f0132fedb88be4a1685a02709fcf_2016_Lynch full and predictives 2016.xlsx.pseudo" \
! -name "ef6964b8789476f4e302b8ec199bd7718b1d101d_2019_Lynch full and predictives 2019.xlsx.pseudo" \
! -name "89d0d99aaccbcb34797c16015267c4cadbee61de_2015_Lynch full and predictives 2015.xlsx.pseudo" \
! -name "3a89d5a61f61b343adca31471ff39f8254226777_2019_PTEN full and predictives 2019.xlsx.pseudo" \
! -name "e10489ceaf13fb0c6bc31ec2195ed6511752571b_01.01.2020 to 31.07.2020_Lynch full and predictives 2020 Jan to July inclusive.xlsx.pseudo" )
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
! -name "89201abfdac7685739944b5a6ea314065ec95d41_01.07.2018 to 01.12.2018_Lynch Challenge July2018_Dec2018v9.xlsx.pseudo" \
! -name "a67fbd953bb8a2df2b9b2ed793a74c6f4ab2efe5_01.01.2010 to 30.06.2018_Lynch Challenge Jan2010_June2018v19.xlsx.pseudo" \
! -name "c7005f8821f316a795e007bff866eaab5e1b0b0d_01.01.2019 to 30.11.2019_Lynch Challenge Jan2019_Nov2019v3.xlsx.pseudo" \
! -name "dc7887680a728a55cb0ae04d1209f963f3d9f429_12.2019_Lynch Challenge Dec2019v7.xlsx.pseudo" \
! -name "4101dd36f57f03ebc1711ec74dba30e15760612d_01.01.2018 to 30.06.2018_Lynch Challenge Jan2018_June2018 additional genes v10.xlsx.pseudo" \
! -name "5108ccb441cb1bf07ab87a580c747aeb644151f6_01.01.2020 to 31.03.2020_Bowel Jan2020_March2020v6.xlsx.pseudo" \
! -name "04401b8fe2742e875d0ce7ebd53ffad7b73954c8_01.04.2020 to 30.06.2020_Bowel April2020_June2020v6.xlsx.pseudo" \
! -name "2781c1ff8d9be78a711016b5348cd1f78a8365cc_01.07.2020 to 30.09.2020_Bowel Julyl2020_Sept2020v5.xlsx.pseudo" \
! -name "6143beeed638c81f50dc60118086e5f4ad5ebfeb_01.10.2020 to 31.12.2020_Bowel Oct2020_Dec2020v3.xlsx.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
MBIS=$1
PROV='RCU'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "1acb5f31aa1f9d057b2105b9ac814c51f6f8bf44_01.04.2014 to 31.12.2018_Colorectal Cancer_09570820181212.csv.pseudo" \
! -name "723f1a253c120dfafe1439bf9150870cd0deda78_01.04.2014 to 01.12.2018_Historical_NonBRCA_NonColorectal_01042014-01122018.csv.pseudo" \
! -name "576f0670b0490bc788f673a5653c28cc1f7e7f7a_01.12.2019 to 31.12.2020_clean_Hereditary_Cancer_BRCA_CRC_31122019_31122020.csv.pseudo" )
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
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  )
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
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
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
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "d66a0bfbd7d994b76c7db3f5c38e2ea3e44118fc_01.2020_CRC2015_2016KGC.xlsx.pseudo" \
! -name "33bb4c02a0627f8bb6b4865e45eed3afab38c2c5_01.2020_CRC2016_2017KGC.xlsx.pseudo" \
! -name "3dfa2592c4f8d9ff996a14f998e1f4d182303857_01.04.2018 to 31.07.2018_CRC data2018Apr_Jul.xlsx.pseudo" \
! -name "5a449342bd13baa4106a828cc7374154de67c0b9_01.04.2017 to 31.03.2018_CRC data2017_2018.xlsx.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RTD; RQ3; RR8; RNZ; RVJ; RX1; RCU; RJ1; RGT; RPY; R0A; RJ7; RTH; R1K


