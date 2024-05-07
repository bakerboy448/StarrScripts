#!/usr/bin/env bash

# chmod +x this script (terminal command e.g. `chmod +x xseed_qbit_cat_filter.sh`)
# put the following execution command in your qbit with its absolute path from qbit's
# perspective (container path if docker).
#
# /path/to/xseed_qbit_cat_filter.sh "%F" "%L" "%N" "%T" "%I"

TORRENT_PATH=$1
TORRENT_CAT=$2
TORRENT_NAME=$3
TORRENT_TRACKER=$4
TORRENT_INFOHASH=$5

set -eu

# fill out cross-seeds information. you will need to adjust the IP/host of cross-seed
# it will need to be accessible from wherever you are executing this script from
# use a full http link to webhook endpoint
# do not use quotes in either variable
XSEED_URL=http://cross-seed:2468/api/webhook
XSEED_API_KEY=

# Filter for categories you want cross seed to search for
# Ex) Radarr-HD|Radarr-UHD|TV|TV-HQ
FILTERED_CAT=CAT1|CAT2|CAT3

# Filter for trackers you want cross seed to search for
# Ex) tracker.announce.com|tracker.announce2.com
FILTERED_TRACKER=tracker1.announce.com|tracker2.announce.com


log() {
  echo -e "${0##*/}: $1"
}
log_err() {
  echo -e "${0##*/}: ERROR: $1" <&2
  exit 1
}

cross_seed_request() {
    local data="$1"
    local headers=(-X POST "$XSEED_URL" --data-urlencode "$data")
    if [ -n "$XSEED_API_KEY" ]; then
        headers+=(-H "X-Api-Key: $XSEED_API_KEY")
    fi
    response=$(curl --silent --output /dev/null --write-out "%{http_code}" "${headers[@]}")
    echo "$response"
}

if [[ -z "$TORRENT_PATH" ]]; then
  log_err 'Torrent data path not specified'
elif [[ ! -e "$TORRENT_PATH" ]]; then
  log_err "Torrent data not found: $TORRENT_PATH"
elif [[ -z "$TORRENT_CAT" ]]; then
  log_err "Category not specified for $TORRENT_PATH"
fi

log "[\033[1m$TORRENT_NAME\033[0m] [$TORRENT_CAT]"


if [[ "$TORRENT_CAT" =~ ^($FILTERED_CAT)$ ]]; then
  xseed_resp=$(cross_seed_request "infoHash=$TORRENT_INFOHASH");
  [ "$xseed_resp" != "204" ] && sleep 30 && xseed_resp=$(cross_seed_request "path=$TORRENT_PATH")
elif [[ "$TORRENT_TRACKER" =~ ($FILTERED_TRACKER) ]]; then
  xseed_resp=$(cross_seed_request "infoHash=$TORRENT_INFOHASH");
  [ "$xseed_resp" != "204" ] && sleep 30 && xseed_resp=$(cross_seed_request "path=$TORRENT_PATH")
fi
