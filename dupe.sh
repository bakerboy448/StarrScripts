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

# Default Variables
JDUPES_OUTPUT_LOG=${JDUPES_OUTPUT_LOG:-"/mnt/data/jdupes.log"}
JDUPES_SOURCE_DIR=${JDUPES_SOURCE_DIR:-"/mnt/data/media/"}
JDUPES_DESTINATION_DIR=${JDUPES_DESTINATION_DIR:-"/mnt/data/torrents/"}
JDUPES_HASH_DB=${JDUPES_HASH_DB:-"/.config/jdupes_hashdb"}
JDUPES_COMMAND=${JDUPES_COMMAND:-"/usr/bin/jdupes"}
JDUPES_EXCLUDE_DIRS=${JDUPES_EXCLUDE_DIRS:-"-X nostr:.RecycleBin -X nostr:.trash"}
JDUPES_INCLUDE_EXT=${JDUPES_INCLUDE_EXT:-"mp4,mkv,avi"}
DEBUG=${DEBUG:-"false"}

find_duplicates() {
    local log_file="$JDUPES_OUTPUT_LOG"
    local start=$(date +%s)
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Duplicate search started" | tee -a "$log_file"

    if [ "$DEBUG" == "true" ]; then
        echo "Running jdupes with:" | tee -a "$log_file"
        echo "$JDUPES_COMMAND $JDUPES_EXCLUDE_DIRS -X onlyext:$JDUPES_INCLUDE_EXT -r -M -y $JDUPES_HASH_DB $JDUPES_SOURCE_DIR $JDUPES_DESTINATION_DIR" | tee -a "$log_file"
    fi

    local results
    results=$("$JDUPES_COMMAND" "$JDUPES_EXCLUDE_DIRS" -X onlyext:"$JDUPES_INCLUDE_EXT" -r -M -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR")

    if [[ $results != *"No duplicates found."* ]]; then
        "$JDUPES_COMMAND" "$JDUPES_EXCLUDE_DIRS" -X onlyext:"$JDUPES_INCLUDE_EXT" -r -L -y "$JDUPES_HASH_DB" "$JDUPES_SOURCE_DIR" "$JDUPES_DESTINATION_DIR" >>"$log_file"
    fi

    if [ "$DEBUG" == "true" ]; then
        echo -e "jdupes output: ${results}" | tee -a "$log_file"
    fi

    parse_jdupes_output "$results" "$log_file"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Duplicate search completed" | tee -a "$log_file"
}

parse_jdupes_output() {
    local results="$1"
    local log_file="$2"

    if [[ $results != *"No duplicates found."* ]]; then
        field_message="❌ Unlinked files discovered..."
        parsed_log=$(echo "$results" | awk -F/ '{print $NF}' | sort -u)
    else
        field_message="✅ No unlinked files discovered..."
        parsed_log="No hardlinks created"
    fi

    if [ "$DEBUG" == "true" ]; then
        echo -e "$field_message" | tee -a "$log_file"
        echo -e "Parsed log: ${parsed_log}" | tee -a "$log_file"
    fi
}

find_duplicates
