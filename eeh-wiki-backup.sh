#!/usr/bin/env bash
#
# eeh-wiki-backup.sh
#
# Backup the EEH Wiki to Azure Storage
#
# Backs up:
# - All wiki files
# - Database
# - Wiki in XML Format
#
# Requires:
# - az cli

set -euo pipefail

KEEP_LOCAL_BACKUP_DAYS=7
START_TIME=$(date)
DATE=$(date +%F_%H%M)
DOW=$(date +%A)
BACKUP_DIR="/opt/backup"
BACKUP_PREFIX="eeh-wiki"
INSTALL_DIR="/opt/bitnami/mediawiki"

# Include Secrets
source $(dirname "$0")/secrets.inc

# Based upon: https://github.com/samwilson/MediaWiki_Backup
function export_xml {
    XML_DUMP="${BACKUP_DIR}/xml/${BACKUP_PREFIX}-xml-${DATE}.gz"
    echo "** Exporting XML to $XML_DUMP"
    cd "$INSTALL_DIR/maintenance"
    ## Make sure PHP is found.
    if hash /opt/bitnami/php/bin/php 2>/dev/null; then
        /opt/bitnami/php/bin/php -d error_reporting=E_ERROR dumpBackup.php \
            --conf="$INSTALL_DIR/LocalSettings.php" \
            --quiet --full --logs --uploads \
            | gzip -9 > "$XML_DUMP"
    else
        echo "Error: Unable to find PHP; not exporting XML" 1>&2
    fi
}

echo "** Change Wiki to Read-only mode"
sed -i '/# EEH Backup Settings/{n;s/#//}' ${INSTALL_DIR}/LocalSettings.php

echo "** Backing up all databases"
/opt/bitnami/mariadb/bin/mariadb-backup --backup --target-dir=/opt/backup/mariadb/ --user=root --password=VE43ZUBgN=Ei  --stream=xbstream | gzip > ${BACKUP_DIR}/mariadb/${BACKUP_PREFIX}-mariadb-${DATE}.gz

echo "** Backing up ${INSTALL_DIR} to ${BACKUP_DIR}/${BACKUP_PREFIX}-mediawiki-${DATE}.tar.gz"
tar czf ${BACKUP_DIR}/mediawiki/${BACKUP_PREFIX}-mediawiki-${DATE}.tar.gz ${INSTALL_DIR}

echo "** Backing up XML"
export_xml

echo "** Re-enable Wiki"
sed -i '/# EEH Backup Settings/{n;/^\$/{s/^/#/}}' ${INSTALL_DIR}/LocalSettings.php


echo "** Syncing Backups to Azure"
az storage file upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCESS_KEY --share-name $AZURE_SHARE_NAME --source ${BACKUP_DIR}/mediawiki/${BACKUP_PREFIX}-mediawiki-${DATE}.tar.gz --path mediawiki

az storage file upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCESS_KEY --share-name $AZURE_SHARE_NAME --source ${BACKUP_DIR}/xml/${BACKUP_PREFIX}-xml-${DATE}.gz --path xml

az storage file upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCESS_KEY --share-name $AZURE_SHARE_NAME --source ${BACKUP_DIR}/mariadb/${BACKUP_PREFIX}-mariadb-${DATE}.gz --path mariadb

echo "** Deleting local backups older than ${KEEP_LOCAL_BACKUP_DAYS} days"
find $BACKUP_DIR -name "*.gz" -type f -mtime +${KEEP_LOCAL_BACKUP_DAYS} -delete

echo
echo " Start: ${START_TIME}"
echo "Finish: $(date)"
