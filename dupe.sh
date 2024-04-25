#!/bin/bash

# Load environment variables from .env file
set -a  # automatically export all variables
source .env
set +a

# Command and options
jdupes_command="/usr/bin/jdupes"
exclude_dirs="-X nostr:.RecycleBin -X nostr:.trash"
include_ext="-X onlyext:mp4,mkv,avi"

# Logging the start of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search started for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >> "$JDUPES_OUTPUT_LOG"

# Running jdupes with the loaded environment variables
$jdupes_command $exclude_dirs $include_ext -L -r -Z -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR" >> "$JDUPES_OUTPUT_LOG"

# Logging the completion of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search completed for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >> "$JDUPES_OUTPUT_LOG"
