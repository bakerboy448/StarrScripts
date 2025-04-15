#!/bin/bash

directory=${1:-.}  # Use provided directory or default to current directory

find "$directory" -type d | while read -r dir; do
    file_count=$(find "$dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.mpg" -o -iname "*.mpeg" \) | wc -l)
    if [[ $file_count -gt 1 ]]; then
        echo "$dir"
    fi
done
