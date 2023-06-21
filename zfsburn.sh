#!/bin/bash

list_snapshots() {
    zfs list -t snapshot -o name "$1" | grep "$2" | tac | tail -n +"$((3 + 1))" | sed 's/.*@//' | tr '\n' ',' | sed 's/,$//'
}

calculate_space() {
    zfs list -H -o used -t snapshot -r "$1" | awk '{ sum += $1 } END { printf "%.2f", sum / (1024^3) }'
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dataset>"
    exit 1
fi

cleanup_snapshot() {
    local dataset="$1"
    local snapshot="$2"

    if [ -n "$snapshot" ]; then
        # Check if the snapshot still exists
        if zfs list -t snapshot -o name "$dataset@$snapshot" >/dev/null 2>&1; then
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

for dataset in $(zfs list -r -o name "$1" | tail -n +2); do
    while :; do
        # Remove "system" snapshots.
        valid_state=$(list_snapshots "$dataset" valid-state 0)
        update=$(list_snapshots "$dataset" update 0)

        # Keep X frequent, Y hourly, Z daily, D weekly, and E monthly snapshots.
        old_frequent=$(list_snapshots "$dataset" frequent 2)
        old_hourly=$(list_snapshots "$dataset" hourly 2)
        old_daily=$(list_snapshots "$dataset" daily 0)
        old_weekly=$(list_snapshots "$dataset" weekly 0)
        old_monthly=$(list_snapshots "$dataset" monthly 0)

        snapshots_to_delete=$(echo "$valid_state$update$old_frequent$old_hourly$old_daily$old_weekly$old_monthly" | sed 's/.$//' | tr ',' '\n' | sort)

        if [[ -z "$snapshots_to_delete" ]]; then
            break
        fi

        deleted_snapshots=0  # Variable to track the number of deleted snapshots

        for snapshot in $snapshots_to_delete; do
            if cleanup_snapshot "$dataset" "$snapshot"; then
                deleted_snapshots=$((deleted_snapshots + 1))
            fi
        done

        if [[ $deleted_snapshots -eq 0 ]]; then
            break
        fi
    done
done
