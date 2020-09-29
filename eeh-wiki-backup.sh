#!/usr/bin/env bash
#
# eeh-wiki-backup.sh
#
# Backup the EEH Wiki to an S3 Bucket
#
# Backs up:
# - All wiki files
# - Database
# - Wiki in XML Format
#
# Requires:
# - automysqlbackup
# - awscli
#
# Notes:
# - no backup rotation logic

set -euo pipefail

START_TIME=$(date)
DATE=$(date +%F_%H%M)
BACKUP_DIR="/root/eeh-wiki-backups/backups"
BACKUP_PREFIX="eeh-wiki"
INSTALL_DIR="/var/lib/mediawiki"
S3_BUCKET="s3://eeh-wiki-backups/"

# Based upon: https://github.com/samwilson/MediaWiki_Backup
function export_xml {
    XML_DUMP="${BACKUP_DIR}/${BACKUP_PREFIX}-xml-${DATE}.gz"
    echo "Exporting XML to $XML_DUMP"
    cd "$INSTALL_DIR/maintenance"
    ## Make sure PHP is found.
    if hash php 2>/dev/null; then
        php -d error_reporting=E_ERROR dumpBackup.php \
            --conf="$INSTALL_DIR/LocalSettings.php" \
            --quiet --full --logs --uploads \
            | gzip -9 > "$XML_DUMP"
    else
        echo "Error: Unable to find PHP; not exporting XML" 1>&2
    fi
}

echo "** Change Wiki to Read-only mode"
sed -i 's/EEH-MESSAGE/Daily Backup/1' ${INSTALL_DIR}/LocalSettings.php
sed -i 's/#$wgIgnoreImageErrors/$wgIgnoreImageErrors/1' ${INSTALL_DIR}/LocalSettings.php
sed -i 's/#$wgReadOnly/$wgReadOnly/1' ${INSTALL_DIR}/LocalSettings.php

echo "** Backing up all databases"
automysqlbackup

echo "** Backing up ${INSTALL_DIR} to ${BACKUP_DIR}/${BACKUP_PREFIX}-backup-${DATE}.tar.gz"
tar czf ${BACKUP_DIR}/${BACKUP_PREFIX}-backup-${DATE}.tar.gz ${INSTALL_DIR}

echo "** Backing up XML"
export_xml

echo "** Re-enable Wiki"
sed -i 's/$wgReadOnly/#$wgReadOnly/1' ${INSTALL_DIR}/LocalSettings.php
sed -i 's/$wgIgnoreImageErrors/#$wgIgnoreImageErrors/1' ${INSTALL_DIR}/LocalSettings.php
sed -i 's/Daily Backup/EEH-MESSAGE/1' ${INSTALL_DIR}/LocalSettings.php

echo "** Syncing Backups to ${S3_BUCKET}"
aws s3 sync /var/lib/automysqlbackup/daily ${S3_BUCKET}
aws s3 sync ${BACKUP_DIR} ${S3_BUCKET}

echo
echo " Start: ${START_TIME}"
echo "Finish: $(date)"
