#!/bin/bash
BRAKE='bundle exec rake'
#db_cycle

OIFS="$IFS"
IFS=$'\n'

RVJ () {
MBIS=~/work/mbis2_again
PROV='RVJ'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"  \
      -not -path "*/2017-05-09/*"    \
      -not -path "*/2017-06-15/*"  )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RTD () {
    MBIS=~/work/mbis2_again
    PROV='RTD'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"  \
		 -not -path "*/2017-05-11/*" \
		 -not -path "*/2017-08-02/*" \
		 -not -path "*/2017-12-04/*"  )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RR8 () {
MBIS=~/work/mbis2_again
    PROV='RR8'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"  \
      -not -path "*/2017-03-17/*"  )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RNZ () {
MBIS=~/work/mbis2_again
    PROV='RNZ'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*" \
          -not -path "*/2018-02-06/*")
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}


RX1 () {
    MBIS=~/work/mbis2_again
PROV='RX1'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"  \
		 -not -path "*/2017-06-14/*"  )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RCU () {
    MBIS=~/work/mbis2_again
PROV='RCU'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"   )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RW3 () {
    MBIS=~/work/mbis2_again
PROV='RW3'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"   )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3 () {
    MBIS=~/work/mbis2_again
PROV='RQ3'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"   )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RJ1 () {
    MBIS=~/work/mbis2_again
PROV='RJ1'
IFS=$'\n'
for x in $(find  $MBIS/private/pseudonymised_data/ -type f -name "*.pseudo" -path "*/$PROV/*"   )
do
    IFS="$OIFS"
    $BRAKE import:brca fname="$(echo "$x" | sed -e 's:.*pseudonymised_data/\(.*\):\1:')" prov_code=$PROV
done
}

RQ3; RR8; RNZ; RVJ; RTD; RX1; RCU; RW3; RJ1
#RQ3
#RX1; RCU
#RTD
#RR8


