#!/bin/bash

set -e

PREFIX="report"
DATE=$(date +"%Y-%m-%d" --date="yesterday")
#DATE="2017-10-31"
FILENAME="csv/${PREFIX}-${DATE}.csv"
YESTERDAY_REPORT="csv/yesterday_report.csv"
INDEX_HTML="index.html"

HEADER="include/header.html"
FOOTER="include/footer.html"
TABLE="include/table.html"

# Generate yesterday report .csv
cut -f "2,7,8,15,16,18,21" -d"," "${FILENAME}" | sed -r "s/Measurement1 //g" > "${YESTERDAY_REPORT}"

# Generate html table
cat "${HEADER}" > "${INDEX_HTML}"
sed -i -r "s/YYYY.MM.DD/$DATE/g" "${INDEX_HTML}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/" > "${TABLE}"
tail -n +2 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/" >> "${TABLE}"
cat "${TABLE}" >> "${INDEX_HTML}"
cat "${FOOTER}" >> "${INDEX_HTML}"

exit 0
