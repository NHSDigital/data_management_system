#!/bin/bash
COL_NAME="$1"
YEAR_PATTERN="$2"
if [ -z "$COL_NAME" -o -z "$YEAR_PATTERN" ]; then
  echo Error: Syntax `basename "$0"` COL_NAME YEAR_PATTERN
  echo e.g. to extract rows with a DOR column starting with 2018, use
  echo `basename "$0"` DOR ^2018
  exit 1
fi
(
  ruby --encoding=windows-1252 -rcsv -e 'CSV($stdin) do |csv_in|
    dor_col = nil
    year_pattern = /'"$YEAR_PATTERN"'/
    csv_in.each_with_index do |row, i|
      if i == 0
        dor_name = "'"$COL_NAME"'"
        dor_col = row.index(dor_name) # header row
        raise "Error: missing column #{dor_name} in header row: #{row.inspect}" unless dor_col
      else
        next unless year_pattern.match?(row[dor_col]) # skip rows for older years
      end
      print row.to_csv(row_sep: "\r\n")
    end
  end'
)
