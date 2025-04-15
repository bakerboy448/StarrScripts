#!/bin/bash

directory=${1:-.}  # Use provided directory or default to current directory

find "$directory" -type d | while read -r dir; do
    # Extract all matching filenames in the directory
files=($(find "$dir" -maxdepth 1 -type f -regextype posix-extended \
    \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.mpg" -o -iname "*.mpeg" \) \
    -regex ".*\([0-9]{4}\).*S[0-9]{2}E([0-9]{2}).*" | sed -E 's/.*E([0-9]{2}).*/\1/'))

    # Count occurrences of each episode number
    declare -A ep_count
    for ep in "${files[@]}"; do
        ((ep_count[$ep]++))
    done

    # Check if any episode appears more than once
    matched=0
    for count in "${ep_count[@]}"; do
        if [[ $count -gt 1 ]]; then
            matched=1
            break
        fi
    done

    # Print the directory if it has matching files
    if [[ $matched -eq 1 ]]; then
        echo "$dir"
    fi

    # Clear the associative array for the next directory
    unset ep_count
done
