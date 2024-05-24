# EEH Wiki Backup Scripts

Backup the EEH Wiki to an Azure Filestore

## Backs up
- All wiki files
- Database
- Wiki in XML Format

## Requires
- mariadb-backup (comes preinstalled with MariaDB)
- (azure cli)[https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt]

## Notes
- disables write access to wiki whilst backup occuring

## Installation
1. Install azure-cli: `apt-get install azure-cli -y`
1. Clone repo to /opt/backup: `git clone git@github.com:eehackspace/eeh-wiki-backups.git /opt/backup`
1. Rename secrets.inc.example to secrets.inc `mv secrets.inc.example secrets.inc`
1. Add the Azure storage credtentials to `secrets.inc`
1. Install cronjob: `cp /opt/backup/cron/eeh-wiki-backup-cron /etc/cron.d/`
1. Configure mediawiki, add the following lines to /opt/bitnami/mediawiki/LocalSettings.php
    ```
    # EEH Backup Settings
    #$wgReadOnly = 'Daily Backup In Progress. Access will be restored shortly.';
    ```
1. Finish
