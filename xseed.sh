#!/bin/bash

torrentclientname="Qbit"
usenetclientname="SABnzbd"
xseed_host="127.0.0.1"
xseed_port="2468"
log_file="/data/media/.config/xseed_db.log"

# Determine app and set variables
if [ -n "$radarr_eventtype" ]; then
    app="radarr"
    clientID=${radarr_download_client}
    downloadID=${radarr_download_id}
    filePath=${radarr_moviefile_path}
    eventType=${radarr_eventtype}
elif [ -n "$sonarr_eventtype" ]; then
    app="sonarr"
    clientID=${sonarr_download_client}
    downloadID=${sonarr_download_id}
    filePath=${sonarr_series_path}
    folderPath=${sonarr_episodefile_sourcefolder}
    eventType=${sonarr_eventtype}
elif [ -n "$Lidarr_EventType" ]; then
    app="lidarr"
    clientID=${lidarr_Download_Client}
    filePath=${lidarr_Artist_Path}
    downloadID=${lidarr_Download_Id}
    eventType=${lidarr_EventType}
else
    echo "Unknown Event Type. Failing."
    exit 1
fi
echo "$app detected with event type $eventType"

# Function to send request to cross-seed
cross_seed_request() {
    local endpoint=$1
    local data=$2
    curl --silent --output /dev/null --write-out "%{http_code}" -XPOST http://"$xseed_host":"$xseed_port"/api/"$endpoint" --data-urlencode "$data"
}

# Create the log file if it doesn't exist
[ ! -f "$log_file" ] && touch "$log_file"

# Check if the downloadID exists in the log file
unique_id="${downloadID}-${clientID}"
grep -qF "$unique_id" "$log_file"
if [ $? -eq 0 ]; then
    echo "UniqueDownloadID $unique_id has already been processed. Skipping..."
    exit 0
fi

# Handle Unknown Event Type
[ -z "$eventType" ] && echo "Unknown Event Type. Failing." && exit 1

# Handle Test Event
[ "$eventType" == "Test" ] && echo "Test passed for $app. DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath" && exit 0

# Ensure we have necessary details
[ -z "$downloadID" ] && echo "DownloadID is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and DownloadId: $downloadID" && exit 0
[ -z "$filePath" ] && echo "FilePath is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and FilePath: $filePath" && exit 0
[ -z "$folderPath" ] && echo "FolderPath is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and FolderPath: $folderPath" && exit 0

# Handle client based operations
case "$clientID" in
    "$torrentclientname")
        echo "Client $torrentclientname trigged id search for DownloadId $downloadID with FilePath $filePath and FolderPath $folderPath"
        xseed_resp=$(cross_seed_request "webhook" "infoHash=$downloadID")
        ;;
    "$usenetclientname")
        if [[ "$folderPath" =~ S[0-9]{1,2}(?!\.E[0-9]{1,2}) ]]; then
            echo "Client $usenetclientname skipped search for FolderPath $folderPath due to being a SeasonPack for Usenet"
            exit 0
        else
            echo "Client $usenetclientname trigged data search for DownloadId $downloadID with FilePath $filePath and FolderPath $folderPath"
            xseed_resp=$(cross_seed_request "webhook" "path=$filePath")
        fi
        ;;
    *)
        echo "Client $clientID does not match configured Client of $torrentclientname or $usenetclientname. Skipping..."
        exit 0
        ;;
esac


# Handle Cross Seed Response
[ "$xseed_resp" == "204" ] && echo "Success. cross-seed search triggered by $app for DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath" && echo "$UniqueDownloadID" >> "$log_file" && exit 0

echo "cross-seed webhook failed - HTTP Code $xseed_resp from $app for DownloadClient: $clientID, DownloadId: $downloadID and FilePath: $filePath"
exit 1
