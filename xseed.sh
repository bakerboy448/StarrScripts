#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    # shellcheck source=.env
    source ".env"
fi

# Use environment variables with descriptive default values
TORRENT_CLIENT_NAME=${TORRENT_CLIENT_NAME:-Qbit}
USENET_CLIENT_NAME=${USENET_CLIENT_NAME:-SABnzbd}
XSEED_HOST=${XSEED_HOST:-crossseed}
XSEED_PORT=${XSEED_PORT:-8080}
LOG_FILE=${LOG_FILE:-/var/log/xseed.log}

# Function to send a request to Cross Seed API
cross_seed_request() {
    local endpoint="$1"
    local data="$2"
    local headers=(-X POST "http://$XSEED_HOST:$XSEED_PORT/api/$endpoint" --data-urlencode "$data")
    if [ -n "$xseed_apikey" ]; then
        headers+=(-H "X-Api-Key: $xseed_apikey")
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
        clientID="$sonarr_download_client"
        # shellcheck disable=SC2154 # These are set by Starr on call
        downloadID="$sonarr_download_id"
        # shellcheck disable=SC2154 # These are set by Starr on call
        filePath="$sonarr_episodefile_path"
        # shellcheck disable=SC2154 # These are set by Starr on call
        folderPath="$sonarr_episodefile_sourcefolder"
        # shellcheck disable=SC2154 # These are set by Starr on call
        eventType="$sonarr_eventtype"
    elif [ -n "$lidarr_eventtype" ]; then
        app="lidarr"
        # shellcheck disable=SC2154 # These are set by Starr on call
        clientID="$lidarr_download_client"
        # shellcheck disable=SC2154 # These are set by Starr on call
        filePath="$lidarr_artist_path"
        # shellcheck disable=SC2154 # These are set by Starr on call
        downloadID="$lidarr_download_id"
        # shellcheck disable=SC2154 # These are set by Starr on call
        eventType="$lidarr_eventtype"
    elif [ -n "$readarr_eventtype" ]; then
        app="readarr"
        # shellcheck disable=SC2154 # These are set by Starr on call
        clientID="$readarr_download_client"
        # shellcheck disable=SC2154 # These are set by Starr on call
        filePath="$readarr_author_path"
        # shellcheck disable=SC2154 # These are set by Starr on call
        downloadID="$readarr_download_id"
        eventType="$readarr_eventtype"
    fi
    [ "$app" == "unknown" ] && {
        echo "Unknown application type detected. Exiting."
        exit 1
    }
}

# Validate the process
validate_process() {
    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
    unique_id="${downloadID}-${clientID}"

    [ -z "$unique_id" ] && return
    grep -qF "$unique_id" "$LOG_FILE" && {
        echo "Download ID $unique_id already processed. Exiting."
        exit 0
    }

    [ -z "$eventType" ] && {
        echo "No event type specified. Exiting."
        exit 1
    }
    [ "$eventType" == "Test" ] && {
        echo "Test event detected. Exiting."
        exit 0
    }
    [ -z "$filePath" ] && [ -z "$downloadID" ] && {
        echo "Essential parameters missing. Exiting."
        exit 1
    }

    if [ -z "$downloadID" ] || [ -z "$filePath" ]; then
        echo "Download ID is missing. Checking if file path works for data/path based cross-seeding."
        if [ -z "$filePath" ]; then
            echo "File path is missing. Exiting."
            exit 1
        fi
    fi

    [ -z "$filePath" ] && [ -z "$downloadID" ] && {
        echo "Essential parameters missing. Exiting."
        exit 1
    }
}

# Main logic for handling operations
handle_operations() {
    detect_application
    validate_process

    case "$clientID" in
    "$TORRENT_CLIENT_NAME")
        echo "Processing torrent client operations..."
        [ -n "$downloadID" ] && { xseed_resp=$(cross_seed_request "webhook" "infoHash=$downloadID"); }
        [ "$xseed_resp" != "204" ] && sleep 15 && xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
        ;;
    "$USENET_CLIENT_NAME")
        [[ "$folderPath" =~ S[0-9]{1,2}(?!\.E[0-9]{1,2}) ]] && {
            echo "Skipping season pack search."
            exit 0
        }
        echo "Processing Usenet client operations..."
        xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
        ;;
    *)
        echo "Unrecognized client $clientID. Exiting."
        exit 1
        ;;
    esac
    echo "Cross-seed API response: $xseed_resp"
    if [ "$xseed_resp" == "204" ]; then
        echo "$unique_id" >>"$LOG_FILE"
        echo "Process completed successfully."
    else
        echo "Process failed with API response: $xseed_resp"
        exit 1
    fi
}

handle_operations
