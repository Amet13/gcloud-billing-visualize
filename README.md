gcloud-billing-visualize
========================

[![License](https://img.shields.io/badge/license-GNU_GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

Visualize your google cloud daily reports for pretty html page with sorting by column titles — https://gcloud-billing.amet13.name/

How to setup
------------

Go to https://console.cloud.google.com/ (Billing -> Go to linked billing account -> Manage billing accounts -> Billing export -> File export).
Set `bucket name`, `report prefix` and `format` (CSV).
Enable billing export.

Mount bucket (next day) after generating billing reports:
```
gcsfuse --key-file=key.json --implicit-dirs --dir-mode=775 --file-mode=775 -o allow_other billing_bucket /srv/billing_bucket
```

Clone repo and edit `generate.bash`:
```
cd /srv/
git clone https://github.com/Amet13/gcloud-billing-visualize
cd gcloud-billing-visualize/

vim generate.bash
PREFIX="your_report_prefix"
FILENAME="/srv/billing_bucket/${PREFIX}-${DATE}.csv"
```

Run script:
```
./generate.bash
```

Add to cron:
```
crontab -e
0 * * * * /srv/gcloud-billing-visualize/generate.bash
```

TODO
----

* charts
* group by columns
