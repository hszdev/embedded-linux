#!/bin/bash

capture_photo() {
    local working_directory="$1"

    local timestamp=$(date +"%H%M%S_%3N")
    local folder=$(date +"%Y-%m-%d")
    local filename="$folder/$timestamp.jpg"

    mkdir -p "$working_directory/$folder"
    rpicam-still -t 1 -o "$working_directory/$filename"

    echo "$filename"
}

create_metadata_file() {
    local photo_path="$1"
    local trigger="$2"
    local working_directory="$3"

    local filename=$(basename "$photo_path")
    local folder=$(dirname "$photo_path")
    local json_file="${filename%.*}.json"

    local hours=${filename:0:2}
    local minutes=${filename:2:2}
    local seconds=${filename:4:2}
    local mseconds=${filename:7:3}
    local create_date=$(TZ="Europe/Copenhagen" date +"%Y-%m-%d %H:%M:%S.%3N%:z" -d "$hours:$minutes:$seconds.$mseconds")
    local create_seconds_epoch=$(date -d "$create_date" +"%s")

    local metadata=$(exiftool -SubjectDistance -ExposureTime -ISO -json "$working_directory/$photo_path")

    echo "$metadata" | jq --arg filename "$filename" \
        --arg create_date "$create_date" \
        --arg create_seconds_epoch "$create_seconds_epoch" \
        --arg trigger "$trigger" \
        '.[0] |  del(.SourceFile) + {
	                        "File Name": $filename,
	                        "Create Date": $create_date,
	                        "Create Seconds Epoch": $create_seconds_epoch,
	                        "Trigger": $trigger
	                     }' >"$working_directory/$folder/$json_file"
    echo "$working_directory/$photo_path"
}

valid_input() {
    if [ -z "$1" ] || [[ ! "$1" =~ ^(Time|Motion|External)$ ]]; then
        echo "Error: First argument must be either 'Time', 'Motion', or 'External'"
        return 1
    fi
    if [ -n "$2" ]; then
        if [ ! -d "$2" ]; then
            echo "Error: Second argument must be a directory"
            return 1
        fi
    fi
}

usage() {
    echo "Usage: $0 <trigger_type> [<working_directory>]"
    echo "  trigger_type: 'Time', 'Motion', or 'External'"
    echo "  working_directory (optional): Directory to save photos (default: current directory)"
    echo "Example: $0 Motion /path/to/save/photos"
}

main() {
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        usage
        exit 1
    fi

    if valid_input "$1" "$2"; then
        local working_directory="${2:-$(pwd)}"
        echo $(create_metadata_file "$(capture_photo "$working_directory")" "$1" "$working_directory")
    else
        echo ""
        usage
        exit 1
    fi
}

main "$@"
