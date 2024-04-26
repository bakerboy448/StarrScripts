#!/bin/bash

# Load environment variables from .env file
# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    # shellcheck source=.env
    source ".env"
fi
# Variables
JDUPES_OUTPUT_LOG=${JDUPES_OUTPUT_LOG:-"/var/log/jdupes.log"}
JDUPES_SOURCE_DIR=${JDUPES_SOURCE_DIR:-"/mnt/data/media/"}
JDUPES_DESTINATION_DIR=${JDUPES_DESTINATION_DIR:-"/mnt/data/torrents/"}
JDUPES_HASH_DB=${JDUPES_HASH_DB:-"/var/lib/jdupes_hashdb"}
## Secret Variables
JDUPES_COMMAND=${JDUPES_COMMAND:-"/usr/bin/jdupes"}
JDUPES_EXCLUDE_DIRS=${JDUPES_EXCLUDE_DIRS:-"-X nostr:.RecycleBin -X nostr:.trash"}
JDUPES_INCLUDE_EXT=${JDUPES_INCLUDE_EXT:-"mp4,mkv,avi"}

# Logging the start of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search started for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >>"$JDUPES_OUTPUT_LOG"
echo "command is"
# Running jdupes with the loaded environment variables
echo $JDUPES_COMMAND "$JDUPES_EXCLUDE_DIRS" "$JDUPES_INCLUDE_EXT" -L -r -Z -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR"
$JDUPES_COMMAND $JDUPES_EXCLUDE_DIRS -X onlyext:$JDUPES_INCLUDE_EXT  -L -r -Z -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR" >>"$JDUPES_OUTPUT_LOG"

# Logging the completion of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search completed for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >>"$JDUPES_OUTPUT_LOG"
