#!/bin/bash

# Constants
VERBOSE=0 # Set this to 1 for trace-level logging, 0 for informational logging
MAX_FREQ=2
MAX_HOURLY=2
MAX_DAILY=1
MAX_WEEKLY=0
MAX_MONTHLY=0

# Logging function based on verbosity level
log() {
    local level="$1"
    local message="$2"
    if ((level == 0)) || ((VERBOSE == 1 && level == 1)); then
        echo "$message"
    fi
}

# Bytes to Human Formatting
bytes_to_human_readable() {
    local bytes=$1
    local units=('B' 'KB' 'MB' 'GB' 'TB' 'PB' 'EB' 'ZB' 'YB')
    local unit=0
    
    while (( bytes > 1024 )); do
        (( bytes /= 1024 ))
        (( unit++ ))
    done
    
    echo "${bytes} ${units[unit]}"
}


# Function to retrieve snapshot counts for a specific snapshot type
get_snapshot_count() {
    local snapshot_type="$1"
    local dataset="$2"
    local snapshot_count=0

    # Filter snapshots based on the snapshot type and count them
    snapshot_count=$(sudo zfs list -t snapshot -o name -r "$dataset" | grep -cE "$dataset@.*$snapshot_type-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$")
    # Return the snapshot count as a variable
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

    # Info log prior to filtering
    log 0 "Total snapshots before filtering: [${#snapshots[@]}]"

    # Loop through snapshots and delete based on frequency limits
    for snapshot in "${snapshots[@]}"; do
        log 1 "Filtering snapshot: [$snapshot]"

        local snapshot_name=${snapshot##*/}
        local snapshot_type=${snapshot_name#*_}
        snapshot_type=${snapshot_type%%-*}

        if [[ "$snapshot_type" == "frequent" || "$snapshot_type" == "hourly" || "$snapshot_type" == "daily" || "$snapshot_type" == "weekly" || "$snapshot_type" == "monthly" ]]; then
            log 0 "Processing snapshot: [$snapshot]"

            local max_count=0
            local current_count=0

            if [[ "$snapshot_type" == "frequent" ]]; then
                max_count=$MAX_FREQ
                current_count=$frequent_count
            elif [[ "$snapshot_type" == "hourly" ]]; then
                max_count=$MAX_HOURLY
                current_count=$hourly_count
            elif [[ "$snapshot_type" == "daily" ]]; then
                max_count=$MAX_DAILY
                current_count=$daily_count
            elif [[ "$snapshot_type" == "weekly" ]]; then
                max_count=$MAX_WEEKLY
                current_count=$weekly_count
            elif [[ "$snapshot_type" == "monthly" ]]; then
                max_count=$MAX_MONTHLY
                current_count=$monthly_count
            fi

            log 1 "Current snapshot count: [$current_count]"
            log 1 "Maximum allowed: [$max_count]"

            if ((current_count > max_count || max_count == 0)); then
                log 0 "Deleting snapshot: [$snapshot]"

                local snapshot_space
                snapshot_space=$(sudo zfs list -o used -H -p "$snapshot" | awk '{print $1}')

                if sudo zfs destroy "$snapshot"; then
                    ((deleted++))
                    ((space_gained += snapshot_space))
                    snapshot_space_formatted=$(bytes_to_human_readable "$snapshot_space")
                    log 0 "Space gained: $snapshot_space_formatted"
                else
                    log 0 "Error deleting snapshot: [$snapshot]"
                fi
            fi
        else
            log 1 "Skipped processing snapshot: [$snapshot] - no match to type: [$snapshot_type]"
        fi
    done

    space_gained_formatted=$(bytes_to_human_readable "$space_gained")
    log 0 "Deleted $deleted snapshots for dataset: [$dataset]. Total space gained: $space_gained_formatted"
}

# Usage: ./zfsburn.sh <dataset>
if [[ $# -lt 1 ]]; then
    echo "Usage: ./zfsburn.sh <dataset>"
    exit 1
fi

# Capture the dataset as a variable
datasets="$1"

# Capture snapshot counts as variables
frequent_count=$(get_snapshot_count "frequent" "$datasets")
hourly_count=$(get_snapshot_count "hourly" "$datasets")
daily_count=$(get_snapshot_count "daily" "$datasets")
weekly_count=$(get_snapshot_count "weekly" "$datasets")
monthly_count=$(get_snapshot_count "monthly" "$datasets")

# Use the snapshot counts as needed in the rest of the script
log 0 "Frequent Snapshot Count: [$frequent_count]"
log 0 "Hourly Snapshot Count: [$hourly_count]"
log 0 "Daily Snapshot Count: [$daily_count]"
log 0 "Weekly Snapshot Count: [$weekly_count]"
log 0 "Monthly Snapshot Count: [$monthly_count]"

delete_snapshots "$datasets"
