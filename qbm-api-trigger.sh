#!/bin/bash

# run_qbit_manage_commands.sh
#
# Sends a POST request to qBit Manage with a given torrent hash to trigger
# actions like "tag_update" and "share_limits".
#
# USAGE:
#   ./run_qbit_manage_commands.sh <torrent_hash>
#
# EXAMPLE:
#   ./run_qbit_manage_commands.sh 123ABC456DEF789XYZ
#
# NOTES:
# - Make sure this script is executable: chmod +x run_qbit_manage_commands.sh
# - The torrent hash is typically passed in automatically by qBittorrent via the "%I" variable.
# - All output is logged to run_qbit_manage_commands.log in the same directory as the script,
#   and also printed to stdout.

set -euo pipefail

API_URL="http://127.0.0.1:4269/api/run-command"
COMMANDS='["tag_update", "share_limits", "rem_unregistered", "recheck"]'

if [[ $# -lt 1 || -z "$1" ]]; then
    echo "Usage: $0 <torrent_hash>" >&2
    exit 1
fi

TORRENT_HASH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/run_qbit_manage_commands.log"

JSON="{\"commands\":${COMMANDS},\"hashes\":[\"${TORRENT_HASH}\"]}"

{
    echo "Sending API call for hash: ${TORRENT_HASH}"
    echo "Payload: ${JSON}"
} | tee -a "${LOG_FILE}"

if curl -fsSL -X POST \
     -H "Content-Type: application/json" \
     -d "${JSON}" \
     "${API_URL}" | tee -a "${LOG_FILE}"; then
    echo "Success" | tee -a "${LOG_FILE}"
else
    echo "Error: qBit Manage API call failed for hash ${TORRENT_HASH}" | tee -a "${LOG_FILE}"
fi
