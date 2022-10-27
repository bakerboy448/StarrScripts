#!/bin/bash

clientname="Qbit"
xseed_host="localhost"
xseed_port="2468"

# Determine app and set variables
if [ -n "$radarr_eventtype" ]; then
    app="radarr"
    clientID=${radarr_download_client}
    downloadID=${radarr_download_id}
    eventType=${radarr_eventtype}
elif [ -n "$sonarr_eventtype" ]; then
    app="sonarr"
    clientID=${sonarr_download_client}
    downloadID=${sonarr_download_id}
    eventType=${sonarr_eventtype}
elif [ -n "$Lidarr_EventType" ]; then
    app="lidarr"
    clientID=${Lidarr_Download_Client}
    downloadID=${Lidarr_Download_Id}
    eventType=${Lidarr_EventType}
else
    echo "Unknown Event Type. Failing."
    exit 1
fi
echo "$app detected with event type $eventType"

# Handle Test Event
if [ "$eventType" == "Test" ]; then
    echo "Test passed for $app. DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
fi
# Ensure we have a downloadID
if [ -z "$downloadID" ]; then
    echo "DownloadID is empty from $app. Skipping cross-seed search. DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
fi
# Ensure we have a clientID and it is what the user configured. If it is, search.
if [ "$clientID" == "$clientname" ]; then
    echo "Client $clientname trigged search for DownloadId $downloadID"
    xseed_resp=$(curl --silent --output /dev/null --write-out "%{http_code}" -XPOST http://"$xseed_host":"$xseed_port"/api/webhook --data-urlencode infoHash="$downloadID")
    echo ""
else
    echo "Client $clientID does not match configured Client of $clientname. Skipping..."
    exit 0
fi
# Handle Cross Seed Response
if [ "$xseed_resp" == "204" ]; then # 204 = Success per Xseed docs
    echo "Success. cross-seed search triggered by $app for DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
else
    echo "cross-seed webhook failed - HTTP Code $xseed_resp from $app for DownloadClient: $clientID and DownloadId: $downloadID"
    exit 1
fi
