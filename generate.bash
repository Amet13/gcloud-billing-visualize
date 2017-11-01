#!/bin/bash

set -e

PREFIX="report"
BUCKET_PATH="./csv"
DATE=$(date +"%Y-%m-%d" --date="yesterday")
#DATE="2017-10-31" # I'm using it for demo
FILENAME="${BUCKET_PATH}/${PREFIX}-${DATE}.csv"
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

# Compute engine
echo -e "</table>\n<h1>Compute engine:</h1>\n<table class=\"sortable\">" >> "${TABLE}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/" >> "${TABLE}"
grep "compute-engine" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/" >> "${TABLE}"

# Cloud storage
echo -e "</table>\n<h1>Cloud storage:</h1>\n<table class=\"sortable\">" >> "${TABLE}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/" >> "${TABLE}"
grep "cloud-storage" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/" >> "${TABLE}"

# Other
echo -e "</table>\n<h1>Other services:</h1>\n<table class=\"sortable\">" >> "${TABLE}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/" >> "${TABLE}"
egrep -v "cloud-storage|compute-engine" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/" >> "${TABLE}"

cat "${TABLE}" >> "${INDEX_HTML}"
cat "${FOOTER}" >> "${INDEX_HTML}"

exit 0
