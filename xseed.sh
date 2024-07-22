#!/bin/bash
### UPDATED FOR SEASON PACK FROM USENET SUPPORT IN 
### CROSS SEED v6 ONLY!! v5 IS NOT SUPPORTED FOR USENET
### SEASON PACKS AND WILL ALWAYS FAIL TO FIND MATCHES

### TO ENABLE THIS FEATURE YOU _MUST_ SWITCH TO THE 
### ON IMPORT COMPLETE EVENT TYPE IN YOUR SONARR SETTINGS

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    # shellcheck source=.env
    echo "Loading environment variables from .env file"
    source ".env"
    if [ $? -eq 0 ]; then
        echo "Environment variables loaded successfully"
    else
        echo "Error loading environment variables" >&2
        exit 1
    fi
else
    echo ".env file not found"
fi

# Use environment variables with descriptive default values
TORRENT_CLIENT_NAME=${TORRENT_CLIENT_NAME:-Qbit}
USENET_CLIENT_NAME=${USENET_CLIENT_NAME:-SABnzbd}
XSEED_HOST=${XSEED_HOST:-crossseed}
XSEED_PORT=${XSEED_PORT:-8080}
LOG_FILE=${LOG_FILE:-/config/xseed.log}
XSEED_APIKEY=${XSEED_APIKEY}

# Function to log messages
log_message() {
    local log_type="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$log_type] $message" | tee -a "$LOG_FILE"
}

log_message "INFO" "Script started"
log_message "INFO" "Using environment variables:"
log_message "INFO" "TORRENT_CLIENT_NAME=$TORRENT_CLIENT_NAME"
log_message "INFO" "USENET_CLIENT_NAME=$USENET_CLIENT_NAME"
log_message "INFO" "XSEED_HOST=$XSEED_HOST"
log_message "INFO" "XSEED_PORT=$XSEED_PORT"
log_message "INFO" "LOG_FILE=$LOG_FILE"

# Function to send a request to Cross Seed API
cross_seed_request() {
    local endpoint="$1"
    local data="$2"
    local headers=(-X POST "http://$XSEED_HOST:$XSEED_PORT/api/$endpoint" --data-urlencode "$data")
    if [ -n "$XSEED_APIKEY" ]; then
        headers+=(-H "X-Api-Key: $XSEED_APIKEY")
    fi
    response=$(curl --silent --output /dev/null --write-out "%{http_code}" "${headers[@]}")
    echo "$response"
}

# Detect application and set environment
detect_application() {
    app="unknown"
    if [ -n "$radarr_eventtype" ]; then
        app="radarr"
        # shellcheck disable=SC2154 # These are set by Starr on call
        clientID="$radarr_download_client"
        # shellcheck disable=SC2154 # These are set by Starr on call
        downloadID="$radarr_download_id"
        # shellcheck disable=SC2154 # These are set by Starr on call
        filePath="$radarr_moviefile_path"
        # shellcheck disable=SC2154 # These are set by Starr on call
        eventType="$radarr_eventtype"
    elif [ -n "$sonarr_eventtype" ]; then
        app="sonarr"
        # shellcheck disable=SC2154 # These are set by Starr on call
        sonarrReleaseType="$sonarr_release_releasetype"
        # shellcheck disable=SC2154 # These are set by Starr on call
        clientID="$sonarr_download_client"
        # shellcheck disable=SC2154 # These are set by Starr on call
        downloadID="$sonarr_download_id"
        if [ -n "$sonarrReleaseType" ] && [ "$sonarrReleaseType" == "SeasonPack" ]; then
            # shellcheck disable=SC2154 # These are set by Starr on call
            folderPath="$sonarr_destinationpath"
        else
            [ -z "$sonarr_release_releasetype" ] && {
                # shellcheck disable=SC2154 # These are set by Starr on call
                folderPath="$sonarr_episodefile_sourcefolder"
            }
            # shellcheck disable=SC2154 # These are set by Starr on call
            filePath="$sonarr_episodefile_paths"
        fi
        # shellcheck disable=SC2154 # These are set by Starr on call
        eventType="$sonarr_eventtype"
    fi
    if [ "$app" == "unknown" ]; then
        log_message "ERROR" "Unknown application type detected. Exiting."
        exit 1
    fi
    log_message "INFO" "Detected application: $app"
}

# Validate the process
validate_process() {
    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
    unique_id="${downloadID}-${clientID}"

    if [ -z "$unique_id" ]; then
        log_message "ERROR" "Unique ID is missing. Exiting."
        exit 1
    fi

    if grep -qF "$unique_id" "$LOG_FILE"; then
        log_message "INFO" "Download ID $unique_id already processed. Exiting."
        exit 0
    fi

    if [ -z "$eventType" ]; then
        log_message "ERROR" "No event type specified. Exiting."
        exit 1
    fi

    if [ "$eventType" == "Test" ]; then
        log_message "INFO" "Test event detected. Exiting."
        exit 0
    fi

    if [ -z "$filePath" ] && [ -z "$folderPath" ] && [ -z "$downloadID" ]; then
        log_message "ERROR" "Essential parameters missing. Exiting."
        exit 1
    fi

    if [ -z "$downloadID" ]; then
        log_message "ERROR" "Download ID is missing. Checking if file path works for data/path based cross-seeding."
        if [[ -z "$filePath" && -z "$folderPath" ]]; then
            log_message "ERROR" "File and Folder paths are missing. Exiting."
            exit 1
        fi
    fi
}

# Function to send data for search
send_data_search() {
    if [ -n "$sonarrReleaseType" ] && [ "$sonarrReleaseType" == "SeasonPack" ]; then
        xseed_resp=$(cross_seed_request "webhook" "path=$folderPath")
    else
        xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
    fi
}

# Main logic for handling operations
handle_operations() {
    detect_application
    validate_process
    case "$clientID" in
    "$TORRENT_CLIENT_NAME")
        log_message "INFO" "Processing torrent client operations..."
        if [ -n "$downloadID" ]; then
            xseed_resp=$(cross_seed_request "webhook" "infoHash=$downloadID")
        fi
        if [ "$xseed_resp" != "204" ]; then
            sleep 15
            send_data_search
        fi
        ;;
    "$USENET_CLIENT_NAME")
        if [ -z "$sonarrReleaseType" ] && [[ "$folderPath" =~ S[0-9]{1,2}(?!\.E[0-9]{1,2}) ]]; then
            log_message "WARN" "Depreciated Action. Skipping season pack search. Please switch to On Import Complete for Usenet Season Pack Support!"
            exit 0
        fi
        log_message "INFO" "Processing Usenet client operations..."
        send_data_search
        ;;
    *)
        log_message "ERROR" "Unrecognized client $clientID. Exiting."
        exit 1
        ;;
    esac

    log_message "INFO" "Cross-seed API response: $xseed_resp"
    if [ "$xseed_resp" == "204" ]; then
        echo "$unique_id" >>"$LOG_FILE"
        log_message "INFO" "Process completed successfully."
    else
        log_message "ERROR" "Process failed with API response: $xseed_resp"
        exit 1
    fi
}

handle_operations
