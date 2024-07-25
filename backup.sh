#!/bin/bash

# Read configurations from backup_config.txt
source backup_config.txt

TODAY=$(date +"%d-%b-%Y")

######################################################################
######################################################################

mkdir -p ${DB_BACKUP_PATH}/${TODAY}

echo "Running backup..."
mysqldump --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} ${DATABASE_NAMES} > ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAMES}.sql

# Check if the backup file was created
if [ ! -f ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAMES}.sql ]; then
  echo "Backup failed: ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAMES}.sql not found."
  exit 1
fi

echo "Backup successful: ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAMES}.sql created."

######## Remove backups older than ${BACKUP_RETAIN_DAYS} days ########

DBDELDATE=$(date +"%d-%b-%Y" --date="${BACKUP_RETAIN_DAYS} days ago")

if [ ! -z ${DB_BACKUP_PATH} ]; then
      cd ${DB_BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi

# Compress the created folder

zip -r ${DB_BACKUP_PATH}${TODAY}.zip ${DB_BACKUP_PATH}${TODAY}
rm -rf ${DB_BACKUP_PATH}${TODAY}

# Upload file to FTP server
HOST=${FTP_HOST}
USER=${FTP_USER}
PASSWD=${FTP_PASSWORD}
FILE=${DB_BACKUP_PATH}${TODAY}.zip

ftp -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
binary
passive
cd backups
put $FILE $TODAY.zip
quit
END_SCRIPT

exit 0

######################### End of script ##############################
