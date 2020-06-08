#!/bin/bash

# ----------------------------------------------------------------------------------
# PostgreSQL:
#  Test insertion and selection of text containing a UTF-8 character.
#  ** Assumes presence of `testdb' database, with table `a' and column `t' (text) **
# ----------------------------------------------------------------------------------

u="<database user>"

# UTF-8 code for pi, in hex:
p=$'\xCF\x80'
echo "pi is: $p"

h=$(echo -n $p | xxd -p)
if [ "$h" != "cf80" ]; then
  echo "Incorrect UTF-8 code in shell variable: $h"
  exit 1
fi

psql -U $u testdb -c "DELETE FROM a"
psql -U $u testdb -c "INSERT INTO a VALUES ('$p')"
if [ $? -ne 0 ]; then
  echo "Error $? inserting UTF-8 text into database"
  exit 1
fi

d=$(psql -U $u testdb -t -A -c "SELECT t FROM a")
if [ $? -ne 0 ]; then
  echo "Error $? selecting UTF-8 text from database"
  exit 1
fi

if [ "$d" != "$p" ]; then
  echo "Mismatched UTF-8 code from database: $d"
  exit 1
fi

echo "All UTF-8 tests passed."
