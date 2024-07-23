#!/bin/bash

# Set variables
SOURCE_DIR="/.config"
TEMP_BACKUP_DIR="/tmp"
REMOTE_BACKUP_DIR="/mnt/backup-server/.config"
LOG_FILE="/var/log/rsync-config-backup.log"
TIMESTAMP=$(date +'%Y-%m-%d_%H%M%S')
ARCHIVE_NAME="config_backup_$TIMESTAMP.tar.gz"
EXCLUDE_PATTERNS=(
  '--exclude=*.jpg'
  '--exclude=*.jpeg'
  '--exclude=*.png'
  '--exclude=*.gif'
  '--exclude=*.mp3'
  '--exclude=*.mp4'
  '--exclude=*.avi'
  '--exclude=*.mkv'
  '--exclude=*.flac'
  '--exclude=plexmediaserver/*'
)

# Create the archive in /tmp and check if the archive was created successfully
if tar -czvf "$TEMP_BACKUP_DIR/$ARCHIVE_NAME" "${EXCLUDE_PATTERNS[@]}" -C "$SOURCE_DIR" . >"$LOG_FILE" 2>&1; then
  echo "Archive created successfully: $TEMP_BACKUP_DIR/$ARCHIVE_NAME" >>"$LOG_FILE"

  # Sync the archive to the remote backup directory
  if rsync -av "$TEMP_BACKUP_DIR/$ARCHIVE_NAME" "$REMOTE_BACKUP_DIR" >>"$LOG_FILE" 2>&1; then
    echo "Backup synced successfully: $REMOTE_BACKUP_DIR/$ARCHIVE_NAME" >>"$LOG_FILE"
    # Optionally, remove the local archive after successful sync
    rm "$TEMP_BACKUP_DIR/$ARCHIVE_NAME"
  else
    echo "Failed to sync the backup to the remote server" >>"$LOG_FILE"
  fi
else
  echo "Failed to create the archive" >>"$LOG_FILE"
fi
