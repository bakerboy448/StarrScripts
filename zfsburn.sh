#!/bin/bash

VERBOSE=0  # Set this to 1 to see all messages
MAX_FREQ=2
MAX_HOURLY=2
MAX_DAILY=0
MAX_WEEKLY=0
MAX_MONTHLY=0

list_snapshots() {
    local dataset="$1"
    local filter="$2"
    local max_snapshots="$3"
    zfs list -t snapshot -o name -r "$dataset" | grep "$filter" | awk -F'@|zfs-auto-snap_' '{print $2}'
}

calculate_space() {
    zfs list -H -o used -t snapshot -r "$1" | awk '{ sum += $1 } END { printf "%.2f", sum / (1024^3) }'
}

cleanup_snapshot() {
    local snapshot="$1"

    if [ -n "$snapshot" ]; then
        # Check if the snapshot still exists
        if zfs list -t snapshot -o name | grep -q "^${snapshot}$"; then
            echo "Cleaning up $snapshot..."
            sudo zfs destroy -v "$snapshot"
            space_freed=$(calculate_space "${snapshot%%@*}")
            echo "Space freed: ${space_freed}GB"
            return 1  # Snapshot deleted, indicate with non-zero exit code
        else
            echo "Snapshot $snapshot does not exist. Skipping cleanup."
        fi
    fi

    return 0  # Snapshot not deleted, indicate with zero exit code
}

delete_snapshots() {
    local dataset="$1"
    local filter="$2"
    local max_snapshots="$3"
    
    snapshots=$(list_snapshots "$dataset" "$filter" "$max_snapshots")
    
    if [ -n "$snapshots" ]; then
        echo "Deleting snapshots in dataset: $dataset"
        
        for snapshot in $snapshots; do
            if cleanup_snapshot "$snapshot"; then
                echo "Snapshot $snapshot deleted."
            fi
        done
    elif [ "$VERBOSE" -eq 1 ]; then
        echo "No snapshots to delete in dataset: $dataset."
    fi
}

zfs_list_output=$(zfs list -r -o name -t filesystem -H "$1")

# Check if there are any datasets
if [ -z "$zfs_list_output" ]; then
    if [ "$VERBOSE" -eq 1 ]; then
        echo "No datasets available under $1. Skipping cleanup."
    fi
    exit 0
fi

# If datasets are available, proceed with the cleanup
while IFS= read -r dataset; do
    echo "Processing dataset: $dataset"
    
    delete_snapshots "$dataset" frequent "$MAX_FREQ"
    delete_snapshots "$dataset" hourly "$MAX_HOURLY"
    delete_snapshots "$dataset" daily "$MAX_DAILY"
    delete_snapshots "$dataset" weekly "$MAX_WEEKLY"
    delete_snapshots "$dataset" monthly "$MAX_MONTHLY"
done <<< "$zfs_list_output"
