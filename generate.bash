#!/bin/bash

set -e

bc --version > /dev/null

# Edit this settings
PREFIX="report"
BUCKET_PATH="./csv"
ENABLE_MONTH_REPORT=1
# End settings edit

DATE=$(date +"%Y-%m-%d" --date="2 days ago")
#DATE="2017-11-03" # I'm using it for demo
LAST_MONTH=$(date +'%Y-%m' -d 'last month')
CURRENT_MONTH=$(date +'%Y-%m')

FILENAME="${BUCKET_PATH}/${PREFIX}-${DATE}.csv"
REPORT="csv/report.csv"
INDEX_HTML="index.html"
AWKFILE="cut.awk"
HEADER="include/header.html"
TABLE="include/table.html"

# Patterns
TABLE_CLASS="<table class=\"sortable\">"
TABLE_END="</table>"
HR="\n<hr>\n\n"
COLUMNS="Line Item,Measurement1 Total Consumption,Measurement1 Units,Cost,Currency,Project ID,Description"
CURRENCY="$"
SECTION=""

> "${REPORT}"
# Generate report.csv
{
    echo "${COLUMNS}" | sed -r "s/Measurement1 //g" | sed -r "s/\"//g"
    awk -f "${AWKFILE}" -F "," -v cols="${COLUMNS}" "${FILENAME}"
} >> "${REPORT}"

# Remove empty column
sed -i -r "s/,$//g" "${REPORT}"

TOTAL_COST=$(awk -f "${AWKFILE}" -F "," -v cols=Cost "${REPORT}" | sed -r 's/,//g' | paste -sd+ | bc)
CE_COST=$(egrep "${compute-engine}|Cost" "${REPORT}" | awk -f "${AWKFILE}" -F "," -v cols=Cost  | sed -r 's/,//g' | paste -sd+ | bc)
CS_COST=$(egrep "${cloud-storage}|Cost" "${REPORT}" | awk -f "${AWKFILE}" -F "," -v cols=Cost  | sed -r 's/,//g' | paste -sd+ | bc)
OTHER_COST=$(egrep -v "cloud-storage|compute-engine" "${REPORT}" | awk -f "${AWKFILE}" -F "," -v cols=Cost  | sed -r 's/,//g' | paste -sd+ | bc)

# Generate html table
cat "${HEADER}" > "${INDEX_HTML}"
sed -i -r "s/YYYY.MM.DD/$DATE/g" "${INDEX_HTML}"
sed -i -r -e "s/XXX/$CE_COST/g" -e "s/YYY/$CS_COST/g" -e "s/ZZZ/$OTHER_COST/g" "${INDEX_HTML}"

# Generate report for last and current month
LAST_MONTH_COST=0
CURRENT_MONTH_COST=0
if [[ ${ENABLE_MONTH_REPORT} == "1" ]]; then
    while read DAY; do
        LAST_DAY_COST=$(awk -f "${AWKFILE}" -F "," -v cols=Cost "${DAY}" | sed -r 's/,//g' | paste -sd+ | bc)
        LAST_MONTH_COST=$(echo "${LAST_MONTH_COST}" + "${LAST_DAY_COST}" | bc)
    done < <(ls -1 "${BUCKET_PATH}"/"${PREFIX}"-"${LAST_MONTH}"-*.csv)
    while read DAY; do
        CURRENT_DAY_COST=$(awk -f "${AWKFILE}" -F "," -v cols=Cost "${DAY}" | sed -r 's/,//g' | paste -sd+ | bc)
        CURRENT_MONTH_COST=$(echo "${CURRENT_MONTH_COST}" + "${CURRENT_DAY_COST}" | bc)
    done < <(ls -1 "${BUCKET_PATH}"/"${PREFIX}"-"${CURRENT_MONTH}"-*.csv)
    > "${TABLE}"
    {
        echo -e "<h1>Last month usage (${LAST_MONTH}): ${CURRENCY}${LAST_MONTH_COST}</h1>\n<hr>"
        echo -e "<h1>Current month usage (${CURRENT_MONTH}): ${CURRENCY}${CURRENT_MONTH_COST}</h1>\n<hr>"
    } >> "${TABLE}"
fi

# Add chart
{
    echo -e "<h1>Chart for ${DATE}:</h1>"
    echo -e "<div id=\"chartdiv\"></div>\n<hr>"
} >> "${TABLE}"

# All services
{
    echo -e "<h1>All services:</h1>\n${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    tail -n +2 "${REPORT}" | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${TOTAL_COST}</h2>"
} >> "${TABLE}"

# Compute engine
SECTION="compute-engine"
{
    echo -e "${HR}<h1>Compute engine:</h1>\n${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    grep "${SECTION}" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${CE_COST}</h2>"
} >> "${TABLE}"

# Cloud storage
SECTION="cloud-storage"
{
    echo -e "${HR}<h1>Cloud storage:</h1>\n${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    grep "${SECTION}" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${CS_COST}</h2>"
} >> "${TABLE}"

# Other
{
    echo -e "${HR}<h1>Other services:</h1>\n${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    egrep -v "cloud-storage|compute-engine" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${OTHER_COST}</h2>"
} >> "${TABLE}"

{
cat "${TABLE}"
    echo -e "${HR}<p style=\"text-align:center\">\n<a target=\"_blank\" href=\"https://github.com/Amet13/gcloud-billing-visualize\" title=\"Hosted on GitHub\"><img src=\"images/github_80x15.png\" width=\"80\" height=\"15\" alt=\"Source on GitHub\"/></a>\n</p>"
    echo -e "</body>\n</html>"
} >> "${INDEX_HTML}"

echo "Successfully generated new report"
exit 0
