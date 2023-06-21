#!/bin/bash

MAX_FREQ=2
MAX_HOURLY=2
MAX_DAILY=0
MAX_WEEKLY=0
MAX_MONTHLY=0

list_snapshots() {
    local dataset="$1"
    local filter="$2"
    local max_snapshots="$3"
    local snapshots=$(zfs list -t snapshot -o name -r "$dataset" | grep "$filter" | awk -F'@|zfs-auto-snap_' '{print $2}' | sort -r | tail -n +$(($max_snapshots + 1)))
    echo "$snapshots"
}

calculate_space() {
    zfs list -H -o used -t snapshot -r "$1" | awk '{ sum += $1 } END { printf "%.2f", sum / (1024^3) }'
}

cleanup_snapshot() {
    local dataset="$1"
    local snapshot="$2"

    if [ -n "$snapshot" ]; then
        # Check if the snapshot still exists
        if zfs list -t snapshot -o name -r "$dataset" | grep -q "^${dataset}@${snapshot}$"; then
            echo "Cleaning up $dataset@$snapshot..."
            sudo zfs destroy -v "$dataset@$snapshot"
            space_freed=$(calculate_space "$dataset")
            echo "Space freed: ${space_freed}GB"
            return 1  # Snapshot deleted, indicate with non-zero exit code
        else
            echo "Snapshot $dataset@$snapshot does not exist. Skipping cleanup."
        fi
    fi

    return 0  # Snapshot not deleted, indicate with zero exit code
}

delete_snapshots() {
    local dataset="$1"
    local filter="$2"
    local max_snapshots="$3"
    
    if [ "$max_snapshots" -eq 0 ]; then
        snapshots=$(list_snapshots "$dataset" "$filter" "$max_snapshots")
    else
        snapshots=$(list_snapshots "$dataset" "$filter" "$max_snapshots")
    fi
    
    if [ -n "$snapshots" ]; then
        echo "Deleting snapshots: $snapshots"
        
        for snapshot in $snapshots; do
            if cleanup_snapshot "$dataset" "$snapshot"; then
                echo "Snapshot $dataset@$snapshot deleted."
            fi
        done
    else
        echo "No snapshots to delete."
    fi
}

for dataset in $(zfs list -r -o name -t filesystem "$1" | tail -n +2); do
    echo "Processing dataset: $dataset"
    
    delete_snapshots "$dataset" frequent "$MAX_FREQ"
    delete_snapshots "$dataset" hourly "$MAX_HOURLY"
    delete_snapshots "$dataset" daily "$MAX_DAILY"
    delete_snapshots "$dataset" weekly "$MAX_WEEKLY"
    delete_snapshots "$dataset" monthly "$MAX_MONTHLY"
done
