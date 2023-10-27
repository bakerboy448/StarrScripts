#!/bin/bash

jdupes_command="/usr/bin/jdupes"
exclude_dirs="-X nostr:.RecycleBin -X nostr:.trash"
include_ext="-X onlyext:mp4,mkv,avi"
output_log="/home/bakerboy448/jdupes.log"
source_dir="/data/media/media/"
destination_dir="/data/media/torrents/"
hash_db="/home/bakerboy448/jdupes_hashdb"
media2_dir="/mnt/media2"
media2_hash_db="/home/bakerboy448/jdupes_hashdb_media2"

timestamp=$(date +"%Y-%m-%d %H:%M:%S")
$jdupes_command $exclude_dirs $include_ext -L -r -H -y "$hash_db" "$source_dir" "$destination_dir" > "$output_log"
echo "[$timestamp] Duplicate search completed for source and destination dirs." >> "$output_log"

$jdupes_command -L -r -H -y "$media2_hash_db" "$media2_dir" >> "$output_log"
echo "[$timestamp] Duplicate search completed for /mnt/media2." >> "$output_log"
