#!/bin/bash

torrentclientname="Qbit"
usenetclientname="SABnzbd"
xseed_host="crossseed"
xseed_port="2468"
log_file="/data/media/.config/xseed_db.log"
xseed_apikey=""

# Determine app and set variables
if [ -n "$radarr_eventtype" ]; then
    app="radarr"
    # shellcheck disable=SC2154
    clientID="$radarr_download_client"
    # shellcheck disable=SC2154
    downloadID="$radarr_download_id"
    # shellcheck disable=SC2154
    filePath="$radarr_moviefile_path"
    # shellcheck disable=SC2154
    eventType="$radarr_eventtype"
elif [ -n "$sonarr_eventtype" ]; then
    app="sonarr"
    # shellcheck disable=SC2154
    clientID="$sonarr_download_client"
    # shellcheck disable=SC2154
    downloadID="$sonarr_download_id"
    # shellcheck disable=SC2154
    filePath="$sonarr_episodefile_path"
    # shellcheck disable=SC2154
    folderPath="$sonarr_episodefile_sourcefolder"
    # shellcheck disable=SC2154
    eventType="$sonarr_eventtype"
elif [ -n "$Lidarr_EventType" ]; then
    app="lidarr"
    # shellcheck disable=SC2154
    clientID="$Lidarr_Download_Client"
    # shellcheck disable=SC2154
    filePath="$Lidarr_Artist_Path"
    # shellcheck disable=SC2154
    downloadID="$Lidarr_Download_Id"
    # shellcheck disable=SC2154
    eventType="$Lidarr_EventType"
elif [ -n "$Readarr_EventType" ]; then
    app="readarr"
    # shellcheck disable=SC2154
    clientID="$Readarr_Download_Client"
    # shellcheck disable=SC2154
    filePath="$Readarr_Author_Path"
    # shellcheck disable=SC2154
    downloadID="$Readarr_Download_Id"
    # shellcheck disable=SC2154
    eventType="$Readarr_EventType"
else
    echo "|WARN| Unknown Event Type. Failing."
    exit 1
fi
echo "$app detected with event type $eventType"

# Function to send request to cross-seed
cross_seed_request() {
    local endpoint="$1"
    local data="$2"
    if [  -n "$xseed_apikey" ]; then
        curl --silent --output /dev/null --write-out "%{http_code}" -X POST "http://$xseed_host:$xseed_port/api/$endpoint" -H "X-Api-Key: $xseed_apikey" --data-urlencode "$data"
    else
        curl --silent --output /dev/null --write-out "%{http_code}" -X POST "http://$xseed_host:$xseed_port/api/$endpoint" --data-urlencode "$data"
    fi
}

# Create the log file if it doesn't exist
[ ! -f "$log_file" ] && touch "$log_file"

# Check if the downloadID exists in the log file
unique_id="${downloadID}-${clientID}"
# if id is blank (i.e. manual import skip)
if [ -z "$unique_id" ]; then
    echo "UniqueDownloadID $unique_id is blanking. Ignoring."
    exit 0
fi
# If unique_id is not blank, then proceed with checking the id
grep -qF "$unique_id" "$log_file" && echo "UniqueDownloadID $unique_id has already been processed. Skipping..." && exit 0

# Handle Unknown Event Type
[ -z "$eventType" ] && echo "|WARN| Unknown Event Type. Failing." && exit 1

# Handle Test Event
[ "$eventType" == "Test" ] && echo "Test passed for $app. DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath" && exit 0

# Ensure we have necessary details
[ -z "$downloadID" ] && echo "DownloadID is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and DownloadId: $downloadID" && exit 0
[ -z "$filePath" ] && echo "FilePath is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and FilePath: $filePath" && exit 0

# Handle client based operations
case "$clientID" in
    "$torrentclientname")
        echo "Client $torrentclientname triggered id search for DownloadId $downloadID with FilePath $filePath and FolderPath $folderPath"
        xseed_resp=$(cross_seed_request "webhook" "infoHash=$downloadID")
        ;;
    "$usenetclientname")
        if [[ "$folderPath" =~ S[0-9]{1,2}(?!\.E[0-9]{1,2}) ]]; then
            echo "Client $usenetclientname skipped search for FolderPath $folderPath due to being a SeasonPack for Usenet"
            exit 0
        else
            echo "Client $usenetclientname triggered data search for DownloadId $downloadID using FilePath $filePath with FolderPath $folderPath"
            xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
        fi
        ;;
    *)
        echo "|WARN| Client $clientID does not match configured Clients of $torrentclientname or $usenetclientname. Skipping..."
        exit 0
        ;;
esac

# Handle Cross Seed Response
if [ "$xseed_resp" == "204" ]; then
    echo "Success. Cross-seed search triggered by $app for DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath with FolderPath $folderPath"
    echo "$unique_id" >> "$log_file"
    exit 0
else
    echo "|WARN| Cross-seed webhook failed - HTTP Code $xseed_resp from $app for DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath with FolderPath $folderPath"
    exit 1
fi
