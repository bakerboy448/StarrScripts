#!/bin/bash

clientname="Qbit"
xseed_host="localhost"
xseed_port="2468"

if [ -z "$radarr_eventtype" ]; then
    app="radarr"
    clientID=${radarr_download_client}
    downloadID=${radarr_download_id}
    eventType=${radarr_eventtype}
elif [ -z "$sonarr_eventtype" ]; then
    app="sonarr"
    clientID=${sonarr_download_client}
    downloadID=${sonarr_download_id}
    eventType=${sonarr_eventtype}
else
    echo "Unknown Event Type. Failing."
    exit 1
fi

if [ "$eventType" == "Test" ]; then
    echo "Test passed for $app. DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
fi

if [ -z "$downloadID" ]; then
    echo "DownloadID is empty from $app. Skipping Xseed. DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
fi
if [ "$clientID" == "$clientname" ]; then
    echo "Client $clientname trigged search for DownloadId $downloadID"
    curl -s -o /dev/null -w "%{http_code}"-XPOST http://"$xseed_host":"$xseed_port"/api/webhook --data-urlencode infoHash="$downloadID"
else
    echo "Client $clientID is not configured $clientname. Skipping..."
    exit 0
fi
if [ "$http_code" == "204-XPOST" ]; then
    echo "Success. Xseed Search triggered by $app for DownloadClient: $clientID and DownloadId: $downloadID"
    exit 0
else
    echo "Xseed webhook failed - HTTP Code $http_code from $app for DownloadClient: $clientID and DownloadId: $downloadID"
    exit 1
fi
