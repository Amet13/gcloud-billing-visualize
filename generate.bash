#!/bin/bash

set -e

bc --version > /dev/null

# Edit this settings
PREFIX="report"
BUCKET_PATH="./csv"
ENABLE_MONTH_REPORT=1
# End settings edit

DATE=$(date +"%Y-%m-%d" --date="yesterday")
#DATE="2017-11-03" # I'm using it for demo
LAST_MONTH=$(date +'%Y-%m' -d 'last month')
CURRENT_MONTH=$(date +'%Y-%m')
NEXT_MONTH=$(date +'%Y-%m' -d 'next month')

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
ROW="<div class=\"row\">"
COLUMN="<div class=\"column\">"
DIV="</div>"
SHOW_HIDE="<a id=\"${SECTION}\" href=\"javascript:toggle2('${SECTION}','${SECTION}');\">"

if [[ ! -f ${FILENAME} ]]; then
    echo "File ${FILENAME} does not exists"
    exit 1
fi

# Function for showing and hiding info for sections
show_hide () {
    SHOW_HIDE="<a id=\"my${SECTION}\" href=\"javascript:toggle2('${SECTION}','my${SECTION}');\">show/hide</a>"
}

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
NEXT_MONTH_COST=$(echo "${TOTAL_COST} * 30" | bc)

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
        echo -e "\n${ROW}"
        echo -e "  ${COLUMN}<h1>Last month cost (${LAST_MONTH}): ${CURRENCY}${LAST_MONTH_COST}</h1>${DIV}"
        echo -e "  ${COLUMN}<h1>Current month cost (${CURRENT_MONTH}): ${CURRENCY}${CURRENT_MONTH_COST}</h1>${DIV}"
        echo -e "  ${COLUMN}<h1>Daily cost (${DATE}): ${CURRENCY}${TOTAL_COST}</h1>${DIV}"
        echo -e "  ${COLUMN}<h1>Next month cost prediction (${NEXT_MONTH}): ${CURRENCY}${NEXT_MONTH_COST}</h1>${DIV}"
        echo -e "${DIV}\n\n<hr>\n"
    } >> "${TABLE}"
fi

# Add chart
{
    echo -e "<h1>Chart for ${DATE}:</h1>"
    echo -e "<div id=\"chartdiv\"></div>"
} >> "${TABLE}"

# All services
SECTION="ALL"
show_hide
{
    echo -e "${HR}<h1>All services (${CURRENCY}${TOTAL_COST}): ${SHOW_HIDE}</h1>\n<div id=\"${SECTION}\">"
    echo -e "${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    tail -n +2 "${REPORT}" | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${TOTAL_COST}</h2>"
    echo -e "${DIV}"
} >> "${TABLE}"

# Compute engine
SECTION="compute-engine"
show_hide
{
    echo -e "${HR}<h1>Compute engine (${CURRENCY}${CE_COST}):"
    echo -e "${SHOW_HIDE}</h1>\n<div id=\"${SECTION}\">"
    echo -e "${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    grep "${SECTION}" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${CE_COST}</h2>"
    echo -e "${DIV}"
} >> "${TABLE}"

# Cloud storage
SECTION="cloud-storage"
show_hide
{
    echo -e "${HR}<h1>Cloud storage (${CURRENCY}${CS_COST}):"
    echo -e "${SHOW_HIDE}</h1>\n<div id=\"${SECTION}\">"
    echo -e "${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    grep "${SECTION}" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${CS_COST}</h2>"
    echo -e "${DIV}"
} >> "${TABLE}"

# Other
SECTION="other"
show_hide
{
    echo -e "${HR}<h1>Other services (${CURRENCY}${OTHER_COST}):"
    echo -e "${SHOW_HIDE}</h1>\n<div id=\"${SECTION}\">"
    echo -e "${TABLE_CLASS}"
    head -1 "${REPORT}" | sed -e "s/^/<tr>\n  <th>/" -e "s/,/<\/th>\n  <th>/g" -e "s/$/<\/th>\n<\/tr>/"
    egrep -v "cloud-storage|compute-engine" "${REPORT}" | tail -n +2 | sed -e "s/^/<tr>\n  <td>/" -e "s/,/<\/td>\n  <td>/g" -e "s/$/<\/td>\n<\/tr>/"
    echo -e "${TABLE_END}"
    echo -e "<h2>Total cost: ${CURRENCY}${OTHER_COST}</h2>"
    echo -e "${DIV}"
} >> "${TABLE}"

{
cat "${TABLE}"
    echo -e "${HR}<p style=\"text-align:center\">\n<a target=\"_blank\" href=\"https://github.com/Amet13/gcloud-billing-visualize\" title=\"Hosted on GitHub\"><img src=\"images/github_80x15.png\" width=\"80\" height=\"15\" alt=\"Source on GitHub\"/></a>\n</p>"
    echo -e "</body>\n</html>"
} >> "${INDEX_HTML}"

echo "Successfully generated new report"
exit 0
