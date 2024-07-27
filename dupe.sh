#!/usr/bin/env bash

# Load environment variables from .env file if it exists
# in the same directory as this bash script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/.env"
if [ -f "$ENV_PATH" ]; then
    # shellcheck source=.env
    echo "Loading environment variables from $ENV_PATH file"
    # shellcheck disable=SC1090 # shellcheck sucks
    if source "$ENV_PATH"; then
        echo "Environment variables loaded successfully"
    else
        echo "Error loading environment variables" >&2
        exit 1
    fi
else
    echo ".env file not found in script directory ($ENV_PATH)"
fi

# Variables
JDUPES_OUTPUT_LOG=${JDUPES_OUTPUT_LOG:-"/mnt/data/jdupes.log"}
JDUPES_SOURCE_DIR=${JDUPES_SOURCE_DIR:-"/mnt/data/media/"}
JDUPES_DESTINATION_DIR=${JDUPES_DESTINATION_DIR:-"/mnt/data/torrents/"}
JDUPES_HASH_DB=${JDUPES_HASH_DB:-"/.config/jdupes_hashdb"}
## Secret Variables
JDUPES_COMMAND=${JDUPES_COMMAND:-"/usr/bin/jdupes"}
JDUPES_EXCLUDE_DIRS=${JDUPES_EXCLUDE_DIRS:-"-X nostr:.RecycleBin -X nostr:.trash"}
JDUPES_INCLUDE_EXT=${JDUPES_INCLUDE_EXT:-"mp4,mkv,avi"}

# Logging the start of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search started for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >>"$JDUPES_OUTPUT_LOG"
echo "command is"
# Running jdupes with the loaded environment variables
echo "$JDUPES_COMMAND" "$JDUPES_EXCLUDE_DIRS" -X onlyext:"$JDUPES_INCLUDE_EXT" -L -r -Z -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR"
"$JDUPES_COMMAND" "$JDUPES_EXCLUDE_DIRS" -X onlyext:"$JDUPES_INCLUDE_EXT" -L -r -Z -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR" >>"$JDUPES_OUTPUT_LOG"

# Logging the completion of the operation
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
echo "[$timestamp] Duplicate search completed for $JDUPES_SOURCE_DIR and $JDUPES_DESTINATION_DIR." >>"$JDUPES_OUTPUT_LOG"
