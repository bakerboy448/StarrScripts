#!/bin/bash

# Set variables
SOURCE_DIR="/.config"
BACKUP_DIR="/mnt/backup-server/.config"
LOG_FILE="/var/log/rsync-config-backup.log"
TIMESTAMP=$(date +'%Y-%m-%d_%H%M%S')
ARCHIVE_NAME="config_backup_$TIMESTAMP.tar.gz"
EXCLUDE_PATTERNS=('--exclude=*.jpg' '--exclude=*.jpeg' '--exclude=*.png' '--exclude=*.gif' '--exclude=*.mp3' '--exclude=*.mp4' '--exclude=*.avi' '--exclude=*.mkv' '--exclude=*.flac')

# Create the archive
tar -czvf "$BACKUP_DIR/$ARCHIVE_NAME" "${EXCLUDE_PATTERNS[@]}" -C "$SOURCE_DIR" . > "$LOG_FILE" 2>&1

# Output the result
if [[ $? -eq 0 ]]; then
  echo "Backup successful: $BACKUP_DIR/$ARCHIVE_NAME" >> "$LOG_FILE"
else
  echo "Backup failed" >> "$LOG_FILE"
fi
