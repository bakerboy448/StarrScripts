#!/bin/bash

# Constants
VERBOSE=1  # Set this to 1 for trace-level logging, 0 for informational logging
MAX_FREQ=2
MAX_HOURLY=2
MAX_DAILY=0
MAX_WEEKLY=0
MAX_MONTHLY=0

# Function to retrieve snapshot counts for a specific snapshot type
get_snapshot_count() {
    local snapshot_type="$1"
    local dataset="$2"
    
    # Filter snapshots based on the snapshot type and count them
    snapshot_count=$(sudo zfs list -t snapshot -o name -r "$dataset" | grep -E ".*@$snapshot_type-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$" | wc -l)
    
    echo "$snapshot_count"
}

# Function to delete snapshots based on frequency limits
delete_snapshots() {
    local dataset="$1"
    local snapshots=()
    local deleted=0
    local space_gained=0

    # Retrieve all snapshots for the dataset
    readarray -t snapshots < <(sudo zfs list -t snapshot -H -o name -r "$dataset")

    # Logging function based on verbosity level
    log() {
        local level="$1"
        local message="$2"
        if ((level == 0)) || ((VERBOSE == 1 && level == 1)); then
            echo "$message"
        fi
    }

    # Info log prior to filtering
    log 0 "Total snapshots before filtering: ${#snapshots[@]}"

    # Loop through snapshots and delete based on frequency limits
    for snapshot in "${snapshots[@]}"; do
        log 1 "Filtering snapshot: $snapshot"

        local snapshot_name=${snapshot##*/}
        local snapshot_type=${snapshot_name#*_}
        snapshot_type=${snapshot_type%%-*}

        if [[ "$snapshot_type" == "frequent" || "$snapshot_type" == "hourly" || "$snapshot_type" == "daily" || "$snapshot_type" == "weekly" || "$snapshot_type" == "monthly" ]]; then
            log 0 "Processing snapshot: $snapshot"

            local snapshot_count=$(get_snapshot_count "$snapshot_type" "$dataset")
            local max_count=0

            if [[ "$snapshot_type" == "frequent" ]]; then
                max_count=$MAX_FREQ
            elif [[ "$snapshot_type" == "hourly" ]]; then
                max_count=$MAX_HOURLY
            elif [[ "$snapshot_type" == "daily" ]]; then
                max_count=$MAX_DAILY
            elif [[ "$snapshot_type" == "weekly" ]]; then
                max_count=$MAX_WEEKLY
            elif [[ "$snapshot_type" == "monthly" ]]; then
                max_count=$MAX_MONTHLY
            fi

            log 1 "Current snapshot count: $snapshot_count"
            log 1 "Maximum allowed: $max_count"

            if ((snapshot_count > max_count || max_count == 0)); then
                log 0 "Deleting snapshot: $snapshot"
                sudo zfs destroy "$snapshot"
                ((deleted++))
                local snapshot_space=$(sudo zfs list -o used -H -p "$snapshot")
                ((space_gained += snapshot_space))
                log 0 "Space gained: $(printf "%.2f" "$(bc -l <<< "scale=2; $snapshot_space / 1024")") KB"
            fi
        else
            log 1 "Skipped processing snapshot: $snapshot - no match to type: $snapshot_type"
        fi
    done

    log 0 "Deleted $deleted snapshots for dataset: $dataset. Total space gained: $(printf "%.2f" "$(bc -l <<< "scale=2; $space_gained / 1024")") KB"
}

# Usage: ./zfsburn.sh <dataset>
if [[ $# -lt 1 ]]; then
    echo "Usage: ./zfsburn.sh <dataset>"
    exit 1
fi

delete_snapshots "$1"
