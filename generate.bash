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
TABLE="include/table.html"

# Patterns
TABLE_CLASS="<table class=\"sortable\">"
TABLE_END="</table>"
HR="\n<hr>\n\n"

# Generate yesterday report .csv
cut -f "2,7,8,15,16,18,21" -d"," "${FILENAME}" | sed -r "s/Measurement1 //g" > "${YESTERDAY_REPORT}"

# Generate html table
cat "${HEADER}" > "${INDEX_HTML}"
sed -i -r "s/YYYY.MM.DD/$DATE/g" "${INDEX_HTML}"

> "${TABLE}"
# All services
{
echo -e "<h1>All services:</h1>\n${TABLE_CLASS}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
tail -n +2 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
echo -e "${TABLE_END}"
} >> "${TABLE}"

# Compute engine
{
echo -e "${HR}<h1>Compute engine:</h1>\n${TABLE_CLASS}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
grep "compute-engine" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
echo -e "${TABLE_END}"
} >> "${TABLE}"

# Cloud storage
{
echo -e "${HR}<h1>Cloud storage:</h1>\n${TABLE_CLASS}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
grep "cloud-storage" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
echo -e "${TABLE_END}"
} >> "${TABLE}"

# Other
{
echo -e "${HR}<h1>Other services:</h1>\n${TABLE_CLASS}"
head -1 "${YESTERDAY_REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
egrep -v "cloud-storage|compute-engine" "${YESTERDAY_REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
echo -e "${TABLE_END}"
} >> "${TABLE}"

{
cat "${TABLE}"
echo -e "${HR}<p style=\"text-align:center\">\n<a target=\"_blank\" href=\"https://github.com/Amet13/gcloud-billing-visualize\" title=\"Hosted on GitHub\"><img src=\"images/github_80x15.png\" width=\"80\" height=\"15\" alt=\"Source on GitHub\"/></a>\n</p>"
echo -e "</body>\n</html>"
} >> "${INDEX_HTML}"

exit 0
