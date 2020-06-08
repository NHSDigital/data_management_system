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
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
-not -path "*/2017-05-11/*" -not -path "*/2017-08-02/*" -not -path "*/2017-12-04/*" -not -path "*/2017-05-24/*" -not -path "*/2017-05-19/*" -not -path "*/2017-05-23/*" -not -path "*/2018-09-07/*" -not -path "*/2018-09-11/*" -not -path "*/2018-10-30/*" \
! -name "c2181244d67359b9e441236205c04eff221618ef_01.02.2017 to 30.04.2017 01:00_2017-02 to 2017-04.xlsx.pseudo" \
! -name "e82e58f0dbfd4592c3d2e3fb89f9f19e543a30e7_01.11.2006 to 31.12.2007_2006-2007 Data New.xlsx.pseudo" \
! -name "8608f90c10cf90a0717e17081294890bbfb4553d_01.2017_01.01.2017-31.01.2017 Data.xlsx.pseudo" \
! -name "c687591ef56698ec8dde11e2a7420caea0c6173c_09.2018_CAPP2 Pilot data upload.xlsx.pseudo" \
! -name "3268d1e4e28913926cc534d3b8658eca36907050_09.2018_CAPP2 Full Data Upload.xlsx.pseudo"  \
! -name "a34f62c8499c20a48d5c5c228f5084f8f994e84c_10.2018_CAPP2 Full Data Upload.xlsx.pseudo" \
! -name "dda53265da69898d1e9725919a3a706c5003cd79_01.11.2006 to 30.06.2019_NUTH Colorectal Data - November 2006 to June 2019.xlsx.pseudo")
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
! -name "3a4d3dc703789864fa6d2b8f5d9fe60749205979_01.01.2013 to 30.09.2018_010113_300918.xlsx.pseudo" ! -name "c658a0516d5e91acefc59ece77126c50b6a774cc_01.01.2006 to 31.03.2018_MMR gene 2006_31032018.xlsx.pseudo")
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
! -name "8a54ec7127071ef7098b7f93ae501dd12b67a479_01.2017_BRCA 01012017-01032017 upload 1.xlsx.pseudo" \
! -name "cbf7003a4da5ff8e96521f3c931f09b04dcb637c_01.03.2017 to 31.03.2017 01:00_BRCA 01012017-31032017 upload 2.xlsx.pseudo" \
! -name "21293a620f5f3e542c2cf4c35420e6ccfe3947f3_12.2016_BRCA 01102016-31122017.xlsx.pseudo" \
! -name "49615961f4c704a3558887c3fbc40e6de36f1480_01.09.2016 01:00 to 30.09.2016 01:00_BRCA 01072016-30092016.xlsx.pseudo" \
! -name "945e971125c451609bcdb647d867168294e4655f_01.04.2015 01:00 to 30.03.2016 01:00_BRCA 01042015-30032016.xlsx.pseudo" \
! -name "cf1bbaf0c49c586e7c5f2029fe4a173996c9973c_01.04.2009 01:00_01042009-01082010.xlsx.pseudo" \
! -name "aa9d3884bfac6c514c0a2310a2447c1c6da2ce9c_01.06.2016 01:00 to 30.06.2016 01:00_BRCA 01042016-30062016.xlsx.pseudo" \
! -name "ac68d7efdfd16cfc76e97d63bcd52f49e9e4f4a7_01.04.2014 01:00 to 31.03.2015 01:00_BRCA 01042014-31032015.xlsx.pseudo" \
! -name "983859e427c514bd4b5a84308c1bfc9cd72d5196_01.08.2010 01:00 to 01.04.2014 01:00_all upto 01042014.xlsx.pseudo" \
! -name "32b125df2fd306c7b2b6b7a6ec1362d368a02536_2017_Lynch full and predictives 2017.xlsx.pseudo" \
! -name "655e2321cd97be403ad7cf120b4132c52a26d79b_2018_Lynch full and predictives 2018.xlsx.pseudo" \
! -name "d47bfb9be436f0132fedb88be4a1685a02709fcf_2016_Lynch full and predictives 2016.xlsx.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RX1 () {
MBIS=$1
PROV='RX1'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" -not -path "*/2017-06-14/*" ! -name "c7df76254f724581f4b53c522a089f5daf40a4d0_01.10.2017 01:00 to 31.10.2017_BRCA Challenge raw StarLIMS data 2010_June 2017v10.xlsx.pseudo" ! -name "89201abfdac7685739944b5a6ea314065ec95d41_01.07.2018 to 01.12.2018_Lynch Challenge July2018_Dec2018v9.xlsx.pseudo" ! -name "a67fbd953bb8a2df2b9b2ed793a74c6f4ab2efe5_01.01.2010 to 30.06.2018_Lynch Challenge Jan2010_June2018v19.xlsx.pseudo")
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
MBIS=$1
PROV='RCU'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*"  \
! -name "d579be1d694cbc473cd215812dedacb9aebd1334_01.08.2017 01:00 to 31.08.2017 01:00_SDGS_BRCA_812017_912017_Submit2.xlsx.pseudo"   ! -name "1acb5f31aa1f9d057b2105b9ac814c51f6f8bf44_01.04.2014 to 31.12.2018_Colorectal Cancer_09570820181212.csv.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RW3 () {
MBIS=$1
PROV='RW3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*") 
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3 () {
MBIS=$1
PROV='RQ3'
IFS=$'\n'
for x in $(find  $DIRPATH/$FILEPATH -type f -name "*.pseudo" -path "*/$PROV/*" \
! -name "2a58ec5b3ea379d3e8238f7f1234b59166cec5bc_01.01.2010 to 31.05.2017_brca_0110_0517_bwnft.csv.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
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
! -name "217deb0b244d5cd52288e1b74fb453863a6cb17d_01.07.2016 to 31.08.2016_0107_3108_brca_challenge.csv.pseudo" \
! -name "97ef1a03780c6a0f83490c8ce6342927ba06ef4e_01.07.2016 to 31.08.2017_1607_1708_batch2.csv.pseudo" \
! -name "fe8c5fdb3f78710ef06c38b243cccc7fba7906e2_01.07.2016 to 31.08.2017_1607_1708_batch3.csv.pseudo" \
! -name "ebf1c98192bb5904086ad190bf41ffc40a810d9a_01.09.2016 to 04.08.2017_1607_1708.csv.pseudo" )
do
IFS="$OIFS"
$BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RQ3; RR8; RNZ; RVJ; RTD; RX1; RCU; RW3; RJ1; RGT
#RQ3
#RX1; RCU
#RTD
#RR8


