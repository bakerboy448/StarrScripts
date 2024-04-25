#!/bin/bash

# Load environment variables
source ./.env

# Function to send a request to Cross Seed API
cross_seed_request() {
    local endpoint="$1"
    local data="$2"
    local headers=(-X POST "http://$xseed_host:$xseed_port/api/$endpoint" --data-urlencode "$data")
    if [ -n "$xseed_apikey" ]; then
        headers+=(-H "X-Api-Key: $xseed_apikey")
    fi
    response=$(curl --silent --output /dev/null --write-out "%{http_code}" "${headers[@]}")
    echo $response
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
        clientID="$sonarr_download_client"
        downloadID="$sonarr_download_id"
        filePath="$sonarr_episodefile_path"
        folderPath="$sonarr_episodefile_sourcefolder"
        eventType="$sonarr_eventtype"
    elif [ -n "$lidarr_eventtype" ]; then
        app="lidarr"
        clientID="$lidarr_download_client"
        filePath="$lidarr_artist_path"
        downloadID="$lidarr_download_id"
        eventType="$lidarr_eventtype"
    elif [ -n "$readarr_eventtype" ]; then
        app="readarr"
        clientID="$readarr_download_client"
        filePath="$readarr_author_path"
        downloadID="$readarr_download_id"
        eventType="$readarr_eventtype"
    fi
    [ "$app" == "unknown" ] && { echo "Unknown application type detected. Exiting."; exit 1; }
}

# Validate the process
validate_process() {
    [ ! -f "$log_file" ] && touch "$log_file"
    unique_id="${downloadID}-${clientID}"

    [ -z "$unique_id" ] && return
    grep -qF "$unique_id" "$log_file" && { echo "Download ID $unique_id already processed. Exiting."; exit 0; }

    [ -z "$eventType" ] && { echo "No event type specified. Exiting."; exit 1; }
    [ "$eventType" == "test" ] && { echo "Test event detected. Exiting."; exit 0; }
    [ -z "$downloadID" ] || [ -z "$filePath" ] && { echo "Essential parameters missing. Exiting."; exit 1; }
}

# Main logic for handling operations
handle_operations() {
    detect_application
    validate_process

    case "$clientID" in
        "$torrentclientname")
            echo "Processing torrent client operations..."
            xseed_resp=$(cross_seed_request "webhook" "infoHash=$downloadID")
            [ "$xseed_resp" != "204" ] && sleep 15 && xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
            ;;
        "$usenetclientname")
            [[ "$folderPath" =~ S[0-9]{1,2}(?!\.E[0-9]{1,2}) ]] && { echo "Skipping season pack search."; exit 0; }
            echo "Processing Usenet client operations..."
            xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
            ;;
        *)
            echo "Unrecognized client $clientID. Exiting."
            exit 1
            ;;
    esac
    echo "Cross-seed API response: $xseed_resp"
    [ "$xseed_resp" == "204" ] && { echo "$unique_id" >> "$log_file"; echo "Process completed successfully."; } || { echo "Process failed with API response: $xseed_resp"; exit 1; }
}

handle_operations
