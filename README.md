# EEH Wiki Backup Scripts

Backup the EEH Wiki to an S3 Bucket

## Backs up
- All wiki files
- Database
- Wiki in XML Format

## Requires
- automysqlbackup
- awscli

## Notes
- no backup rotation logic
- disables write access to wiki whilst backup occuring

## Installation
1. Install automysqlbackup and awscli: `apt-get install automysqlbackup awscli -y`
1. Configure AWS Credentials: `aws configure`
1. Clone repo to /root/eeh-wiki-backups: `git clone git@github.com:eehackspace/eeh-wiki-backups.git /root/eeh-wiki-backups`
1. Install cronjob: `cp /root/eeh-wiki-backups/cron/eeh-wiki-backup-cron /etc/cron.daily`
1. Configure mediawiki, add the following lines to /var/lib/mediawiki/LocalSettings.php
  ```
  # EEH Backup Settings
  #$wgReadOnly = 'EEH-MESSAGE';
  #$wgIgnoreImageErrors = true;
  ```
1. Finish
