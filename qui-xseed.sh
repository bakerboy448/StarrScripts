#!/usr/bin/env bash
# shellcheck disable=SC2154  # Variables are set by Radarr/Sonarr environment
######################## qui-xseed.sh ######################## ##
## Script to trigger a radarr/sonarr "on import" data-based    ##
## search for the file.                                        ##
##                                                             ##
## Adapted from the original xseed.sh                          ##
## Configure the .env file with the following variables        ##
##                                                             ##
## TORRENT_CLIENTS="qBittorrent"                               ##
## USENET_CLIENTS="SABnzbd"                                    ##
## QUI_HOST="qui"                                              ##
## QUI_PORT="7476"                                             ##
## QUI_APIKEY="<api key>"                                      ##
## QUI_TARGET_INSTANCE_ID="<instance id>"                      ##
## QUI_QBIT_PATH_PREFIX="" (optional)                          ##
## QUI_TAGS="" (optional)                                      ##
## LOG_FILE="" (optional)                                      ##
## LOGID_FILE="" (optional)                                    ##
##                                                             ##
## Setup: - in Radarr>Settings>Connect>+>Custom script, choose ##
##          "On Import" and "On File Upgrade" only.            ##
##        - in Sonarr>Settings>Connect>+>Custom script, choose ##
##          "On Import Complete" only.                         ##
## Logic: When sonarr/radarr finished an import, it            ##
##        1) adds the parent dir as a cross-seed data dir in   ##
##           qui                                               ##
##        2) triggers a data based scan of that dir            ##
##        3) polls the qui api every 10,20,... seconds (up to  ##
##           a day) to check for completion before deleting    ##
##         the data dir.                            ##
## Limitation: For sonarr episode searches, it'll scan the     ##
##             whole season folder.                            ##
######################## qui-xseed.sh ######################## ##

VERSION='1.2'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/.env"
OLD_IFS="$IFS"

# Function to log messages
# Only ERROR/WARNING go to stderr (starr captures stderr as |Error| lines which triggers notifiarr alerts)
# All messages go to the log file for debugging
log_message() {
    local log_type="$1"
    local message="$2"
    local log_line
    log_line="$(date '+%Y-%m-%d %H:%M:%S') [$log_type] $message"
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi
    if [[ "$log_type" == "ERROR" || "$log_type" == "WARNING" ]]; then
        echo "$log_line" >&2
    fi
}

log_message "INFO" "qui-xseed.sh script started $VERSION"
EVAR=false
if [ -f "$ENV_PATH" ]; then
    log_message "INFO" "Loading environment variables from $ENV_PATH file"
    # shellcheck source=/dev/null
    if source "$ENV_PATH"; then
        log_message "INFO" "Environment variables loaded successfully"
        # Strip carriage returns (\r) in case the .env was edited on Windows
        QUI_HOST=${QUI_HOST//\r'/}
        QUI_PORT=${QUI_PORT//\r'/}
        QUI_APIKEY=${QUI_APIKEY//\r'/}
        QUI_TARGET_INSTANCE_ID=${QUI_TARGET_INSTANCE_ID//\r'/}
        QUI_QBIT_PATH_PREFIX=${QUI_QBIT_PATH_PREFIX//\r'/}
        QUI_TAGS=${QUI_TAGS//\r'/}
        LOG_FILE=${LOG_FILE//\r'/}
        LOGID_FILE=${LOGID_FILE//\r'/}
        TORRENT_CLIENTS=${TORRENT_CLIENTS//\r'/}
        USENET_CLIENTS=${USENET_CLIENTS//\r'/}
        EVAR=true
    else
        log_message "ERROR" "Error loading environment variables" >&2
        exit 2
    fi
else
    log_message "DEBUG" ".env file not found in script directory ($ENV_PATH)"
fi

if [[ -n "$TORRENT_CLIENTS" || -n "$USENET_CLIENTS" ]]; then
    IFS=','
    read -r -a TORRENT_CLIENTS <<<"$TORRENT_CLIENTS"
    read -r -a USENET_CLIENTS <<<"$USENET_CLIENTS"
else
    TORRENT_CLIENTS=("Qbit")
    USENET_CLIENTS=("SABnzbd")
fi

QUI_HOST=${QUI_HOST:-localhost}
QUI_PORT=${QUI_PORT:-7476}
QUI_APIKEY=${QUI_APIKEY:-your_api_key_here}
QUI_TARGET_INSTANCE_ID=${QUI_TARGET_INSTANCE_ID:-1}
QUI_QBIT_PATH_PREFIX=${QUI_QBIT_PATH_PREFIX:-""}
QUI_TAGS=${QUI_TAGS:-""}

# Default to the script's current directory if empty
LOG_FILE=${LOG_FILE:-"$SCRIPT_DIR/qui_xseed.log"}
LOGID_FILE=${LOGID_FILE:-"$SCRIPT_DIR/qui_xseed_id.log"}

IFS="$OLD_IFS"

log_message "DEBUG" "Using '.env' file for config?: $EVAR"
log_message "INFO" "Using Configuration:"
log_message "INFO" "QUI_HOST=$QUI_HOST"
log_message "INFO" "QUI_PORT=$QUI_PORT"
log_message "INFO" "QUI_TARGET_INSTANCE_ID=$QUI_TARGET_INSTANCE_ID"
log_message "INFO" "QUI_QBIT_PATH_PREFIX=$QUI_QBIT_PATH_PREFIX"
log_message "INFO" "QUI_TAGS=$QUI_TAGS"
log_message "INFO" "LOG_FILE=$LOG_FILE"

# Function to check if a client is in the allowed list
is_valid_client() {
    local client="$1"
    local client_type="$2"
    case $client_type in
    "torrent")
        for allowed_client in "${TORRENT_CLIENTS[@]}"; do
            local clean_allowed
            clean_allowed=$(echo "$allowed_client" | xargs)
            if [[ "$client" == "$clean_allowed" ]]; then
                return 0
            fi
        done
        ;;
    "usenet")
        for allowed_client in "${USENET_CLIENTS[@]}"; do
            local clean_allowed
            clean_allowed=$(echo "$allowed_client" | xargs)
            if [[ "$client" == "$clean_allowed" ]]; then
                return 0
            fi
        done
        ;;
    esac
    return 1
}

# Function to send three-step request to qui API (Create -> Scan -> Delete)
qui_dir_scan_request() {
    local target_path="$1"

    # Escape backslashes and double quotes to ensure valid JSON
    local safe_target_path="${target_path//\\/\\\\}"
    safe_target_path="${safe_target_path//\"/\\\"}"

    # Format tags from comma-separated string to JSON array format
    local json_tags=""
    if [ -n "$QUI_TAGS" ]; then
        IFS=',' read -r -a tag_array <<< "$QUI_TAGS"
        for i in "${!tag_array[@]}"; do
            # Trim leading/trailing whitespace
            local tag_trimmed
            tag_trimmed=$(echo "${tag_array[$i]}" | xargs)
            if [ -n "$tag_trimmed" ]; then
                if [ -z "$json_tags" ]; then
                    json_tags="\"$tag_trimmed\""
                else
                    json_tags="$json_tags, \"$tag_trimmed\""
                fi
            fi
        done
    fi

    log_message "INFO" "Step 1: Creating dir-scan configuration for path: $target_path"

    local create_payload
    create_payload=$(cat <<EOF
    {
      "path": "$safe_target_path",
      "enabled": true,
      "scanIntervalMinutes": 120,
      "targetInstanceId": $QUI_TARGET_INSTANCE_ID,
      "qbitPathPrefix": "$QUI_QBIT_PATH_PREFIX",
      "tags": [$json_tags]
    }
EOF
)

    local tmp_create
    tmp_create=$(mktemp)
    local create_http_code
    create_http_code=$(curl --silent --write-out "%{http_code}" -X POST "http://$QUI_HOST:$QUI_PORT/api/dir-scan/directories" \
        -H "X-API-Key: $QUI_APIKEY" \
        -H "Content-Type: application/json" \
        -H "accept: application/json" \
        -d "$create_payload" -o "$tmp_create")
    local create_curl_exit=$?
    local create_resp
    create_resp=$(cat "$tmp_create")
    rm -f "$tmp_create"

    if [ $create_curl_exit -ne 0 ]; then
        log_message "ERROR" "Step 1 failed: cURL could not connect to qui API (Exit Code: $create_curl_exit)."
        echo "000"
        return
    fi

    if [[ "$create_http_code" -ge 400 ]]; then
        log_message "ERROR" "Step 1 failed: qui API returned HTTP $create_http_code. Response: $create_resp"
        echo "000"
        return
    fi

    local dir_id
    dir_id=$(echo "$create_resp" | grep -o '"id":[0-9]*' | head -n 1 | cut -d':' -f2)

    if [ -z "$dir_id" ]; then
        log_message "ERROR" "Failed to parse directory ID from qui response. Response: $create_resp"
        echo "000"
        return
    fi

    log_message "INFO" "Successfully registered path. Assigned ID: $dir_id"

    log_message "INFO" "Step 2: Triggering manual scan for Directory ID: $dir_id"

    local tmp_trigger
    tmp_trigger=$(mktemp)
    local trigger_resp_code
    trigger_resp_code=$(curl --silent --write-out "%{http_code}" -X POST "http://$QUI_HOST:$QUI_PORT/api/dir-scan/directories/$dir_id/scan" \
        -H "X-API-Key: $QUI_APIKEY" \
        -H "accept: application/json" -o "$tmp_trigger")
    local trigger_curl_exit=$?
    local trigger_resp
    trigger_resp=$(cat "$tmp_trigger")
    rm -f "$tmp_trigger"

    if [ $trigger_curl_exit -ne 0 ]; then
        log_message "ERROR" "Step 2 failed: cURL could not connect to qui API (Exit Code: $trigger_curl_exit)."
    elif [[ "$trigger_resp_code" -ge 400 ]]; then
        log_message "ERROR" "Step 2 failed: qui API returned HTTP $trigger_resp_code. Response: $trigger_resp"
    fi

    if [ "$trigger_resp_code" == "202" ]; then
        log_message "INFO" "Scan successfully queued (202 Accepted). Polling status..."

        # ---------------------------------------------------------
        # POLLING CONFIGURATION (Exponential Backoff)
        # ---------------------------------------------------------
        local current_wait=10         # Starting wait time in seconds
        local poll_multiplier=2       # Multiplier for the wait time (10, 20, 40, 80...)
        local max_total_time=86400    # Maximum total time to wait in seconds (86400s = 1 day)
        # ---------------------------------------------------------

        local elapsed_time=0
        local attempt=1
        local scan_done=false

        while [ $elapsed_time -le $max_total_time ]; do
            local tmp_status
            tmp_status=$(mktemp)
            local status_http_code
            status_http_code=$(curl --silent --write-out "%{http_code}" -X GET "http://$QUI_HOST:$QUI_PORT/api/dir-scan/directories/$dir_id/status" \
                -H "X-API-Key: $QUI_APIKEY" \
                -H "accept: application/json" -o "$tmp_status")
            local status_curl_exit=$?
            local status_resp
            status_resp=$(cat "$tmp_status")
            rm -f "$tmp_status"

            if [ $status_curl_exit -ne 0 ] || [[ "$status_http_code" -ge 400 ]]; then
                log_message "WARNING" "Failed to poll status for ID $dir_id (HTTP $status_http_code). Will retry next loop."
            else
                local current_status
                current_status=$(echo "$status_resp" | grep -o '"status":"[^"]*"' | head -n 1 | cut -d'"' -f4)
                log_message "DEBUG" "Scan status for ID $dir_id: $current_status (Attempt $attempt, Elapsed: ${elapsed_time}s)"

                if [[ "$current_status" == "success" || "$current_status" == "failed" || "$current_status" == "canceled" || "$current_status" == "idle" ]]; then
                    log_message "INFO" "Scan completed with status: $current_status."
                    scan_done=true
                    break
                fi
            fi

            if [ $elapsed_time -ge $max_total_time ]; then
                break
            fi

            local remaining_time=$((max_total_time - elapsed_time))
            local sleep_time=$current_wait
            if [ $sleep_time -gt $remaining_time ]; then
                sleep_time=$remaining_time
            fi

            log_message "INFO" "Scan still running. Waiting ${sleep_time}s before next check..."
            sleep $sleep_time

            elapsed_time=$((elapsed_time + sleep_time))
            current_wait=$((current_wait * poll_multiplier))
            attempt=$((attempt + 1))
        done

        if [ "$scan_done" != true ]; then
            log_message "WARNING" "Scan polling timed out after $max_total_time seconds. Proceeding to cleanup anyway."
        fi

        log_message "INFO" "Step 3: Deleting directory ID $dir_id to prevent recurring scans."

        local tmp_delete
        tmp_delete=$(mktemp)
        local delete_resp_code
        delete_resp_code=$(curl --silent --write-out "%{http_code}" -X DELETE "http://$QUI_HOST:$QUI_PORT/api/dir-scan/directories/$dir_id" \
            -H "X-API-Key: $QUI_APIKEY" \
            -H "accept: application/json" -o "$tmp_delete")
        local delete_curl_exit=$?
        local delete_resp
        delete_resp=$(cat "$tmp_delete")
        rm -f "$tmp_delete"

        if [ $delete_curl_exit -ne 0 ]; then
            log_message "ERROR" "Step 3 failed: cURL could not connect to qui API (Exit Code: $delete_curl_exit)."
        elif [[ "$delete_resp_code" -ge 400 ]]; then
            log_message "ERROR" "Step 3 failed: qui API returned HTTP $delete_resp_code. Response: $delete_resp"
        else
            log_message "INFO" "Directory deletion completed successfully (HTTP $delete_resp_code)."
        fi
    else
        log_message "ERROR" "Failed to trigger scan. Skipping deletion so you can inspect the error in qui."
    fi

    # Output ONLY the trigger response code so the main script can evaluate it
    echo "$trigger_resp_code"
}

# Detect application and set environment
detect_application() {
    app="unknown"
    if [ -n "$radarr_eventtype" ]; then
        app="radarr"
        clientID="$radarr_download_client"
        downloadID="$radarr_download_id"
        filePath="$radarr_moviefile_path"
        eventType="$radarr_eventtype"
    elif [ -n "$sonarr_eventtype" ]; then
        app="sonarr"
        sonarrReleaseType="$sonarr_release_releasetype"
        clientID="$sonarr_download_client"
        downloadID="$sonarr_download_id"
        if [ -n "$sonarrReleaseType" ] && [ "$sonarrReleaseType" == "SeasonPack" ]; then
            folderPath="$sonarr_destinationpath"
        else
            if [ -z "$sonarr_release_releasetype" ]; then
                folderPath="$sonarr_episodefile_sourcefolder"
                filePath="$sonarr_episodefile_path"
            else
                filePath="$sonarr_episodefile_paths"
            fi
        fi
        eventType="$sonarr_eventtype"
    fi

    if [ "$app" == "unknown" ]; then
        log_message "ERROR" "Unknown application type detected. Exiting."
        exit 2
    fi
    log_message "INFO" "Detected application: $app"
}

# Validate the process
validate_process() {
    if [ "$eventType" == "Test" ]; then
        log_message "INFO" "Test event detected. Exiting."
        exit 0
    fi

    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
    [ ! -f "$LOGID_FILE" ] && touch "$LOGID_FILE"
    unique_id="${downloadID}-${clientID}"

    if [ -z "$unique_id" ] || [ "$unique_id" == "-" ]; then
        log_message "ERROR" "Unique ID is missing. Exiting."
        exit 1
    fi

    if grep -qF "$unique_id" "$LOGID_FILE"; then
        log_message "INFO" "Download ID [$unique_id] already processed and logged. Exiting."
        exit 0
    fi

    if [ -z "$filePath" ] && [ -z "$folderPath" ]; then
        log_message "ERROR" "File and Folder paths are missing. qui requires a path. Exiting."
        exit 2
    fi
}

# Function to parse paths and send to qui
send_data_search() {
    local target_dir=""

    # qui requires a directory path. If we only have a file, extract its folder.
    if [ -n "$folderPath" ]; then
        target_dir="$folderPath"
    elif [ -n "$filePath" ]; then
        target_dir="$(dirname "$filePath")"
    fi

    if [ -z "$target_dir" ]; then
        log_message "ERROR" "Could not determine a valid directory path to scan."
        qui_resp="000"
        return
    fi

    qui_resp=$(qui_dir_scan_request "$target_dir")
}

# Main logic for handling operations
handle_operations() {
    detect_application
    validate_process

    if is_valid_client "$clientID" "torrent" || is_valid_client "$clientID" "usenet"; then
        log_message "INFO" "Processing client operations for $clientID..."
        send_data_search
    else
        log_message "ERROR" "Unrecognized client $clientID. Exiting."
        exit 2
    fi

    log_message "INFO" "Final API Pipeline Result Code: $qui_resp"

    if [ "$qui_resp" == "202" ]; then
        echo "$unique_id" >>"$LOGID_FILE"
        log_message "INFO" "Process completed successfully. Target processed and cleaned up."
    else
        if [ "$qui_resp" == "000" ]; then
            log_message "ERROR" "Process Timed Out or Failed internal checks. Exiting."
        fi
        log_message "ERROR" "Process failed with HTTP response: $qui_resp"
        exit 1
    fi
}

handle_operations
