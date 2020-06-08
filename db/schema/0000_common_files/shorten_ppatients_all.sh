#!/bin/bash
sed -E -e '1s/id[12]/&_short/g' -e 's/[0-9a-f]{48},,1$/,,1/' public.ppatients_all.csv > public.ppatients_all_short.csv 
