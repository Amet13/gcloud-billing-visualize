gcloud-billing-visualize
========================

[![License](https://img.shields.io/badge/license-GNU_GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

Visualize your google cloud daily reports with pretty html page — https://gcloud-billing.amet13.name/

How to setup
------------

* Go to https://console.cloud.google.com/
* Billing -> Go to linked billing account -> Manage billing accounts -> Billing export -> File export
* Set `bucket name`, `report prefix` and `format` (CSV)
* Enable billing export

Mount bucket with reports into some directory:
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
BUCKET_PATH="/srv/billing_bucket"
ENABLE_MONTH_REPORT=0 # If you want to disable month report
```

Run script:
```
./generate.bash
Successfully generated new report
```

Add to cron:
```
crontab -e
0 12 * * * /srv/gcloud-billing-visualize/generate.bash &> /dev/null
```

Setup nginx config and set basic authentication:
```
vim /etc/nginx/conf.d/billing-report.conf
server {
    listen      8080;
    server_name billing-report.domain.com;
    root        /srv/gcloud-billing-visualize;
    location / {
        index index.html;
        auth_basic "Closed site";
        auth_basic_user_file /etc/nginx/htpasswd;
    }
}

htpasswd -c -m /etc/nginx/htpasswd username
nginx -s reload
```

Check: http://billing-report.domain[.]com:8080
