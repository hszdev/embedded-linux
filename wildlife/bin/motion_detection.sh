#!/bin/bash

detect_motion() {
    local old_photo="$1"
    local new_photo="$2"
    local script_path="$3"

    if python3 "$script_path" "$old_photo" "$new_photo"; then
        return 0 # Motion detected
    else
        return 1 # No motion detected
    fi
}

save_motion_photo() {
    local image_path="$1"
    local json_file="${image_path%.*}.json"

    local destination_dir="$2"

    if [ -n "$image_path" ]; then
        local filename=$(basename "$image_path")
        local json_filename=$(basename "$json_file")        
		local folder_name=$(basename "$(dirname "$image_path")")	
		
        mkdir -p "$destination_dir/$folder_name"

        jq '.Trigger = "Motion"' "$json_file" >"$destination_dir/$folder_name/$json_filename"
        cp "$image_path" "$destination_dir/$folder_name/$filename"
    fi
}

# Function for displaying usage instructions
usage() {
    echo "Usage: $0 <destination_directory> [<amount_of_photos>] [<photo_cooldown>] [<working_directory>] [<take_photo_script>] [motion_detect_script]"
    echo "  destination_directory: Directory to save motion photos"
    echo "  amount_of_photos (optional): Number of photos to capture (default: -1 to run indefinitely)"
    echo "  photo_cooldown (optional): Cooldown between each photo capture in seconds (default: 1)"
    echo "  working_directory (optional): Directory to save temporary photos (default: /tmp/wildlife-motion-photos)"
    echo "  take_photo_script (optional): Location of the take_photo.sh script (default: /home/emli/embedded-linux/wildlife/bin/take_photo.sh)"
    echo "  motion_detect_script (optional): Location of the motion detection Python script (default: /home/emli/embedded-linux/wildlife/bin/motion_detect.py)"
}

# Function for validating input
validate_input() {
    if [ $# -lt 1 ] || [ $# -gt 6 ]; then
        echo "Error: Invalid number of arguments"
        usage
        exit 1
    fi
    if ! [ -d "$1" ]; then
        echo "Error: Invalid destination directory"
        usage
        exit 1
    fi
    if [ "$#" -ge 2 ] && ! [[ "$2" =~ ^[+-]?[0-9]+$ ]]; then
        echo "Error: Amount of photos must be an integer (use -1 for indefinite)"
        usage
        exit 1
    fi
    if [ "$#" -ge 3 ] && ! [[ "$3" =~ ^[0-9]+$ ]]; then
        echo "Error: Photo cooldown must be a positive integer"
        usage
        exit 1
    fi
    if [ "$#" -ge 4 ] && ! [ -d "$4" ]; then
        echo "Error: Invalid working directory"
        usage
        exit 1
    fi
}

# Main function
main() {
    local destination_directory="$1"
    local amount_of_photos="${2:--1}" # Default to -1 for indefinite
    local photo_cooldown="${3:-1}"
    local working_directory="${4:-/tmp/wildlife-motion-photos}"
    local take_photo_script_location="${5:-/home/emli/embedded-linux/wildlife/bin/take_photo.sh}"
    local motion_detection_script_location="${6:-/home/emli/embedded-linux/wildlife/bin/motion_detect.py}"

    # Validate input
    validate_input "$@"

    # Create temporary directory if not exists
    mkdir -p "$working_directory"

    # Main loop for capturing photos
    local old_photo=""
    while true; do
        local new_photo=$("$take_photo_script_location" Time "$working_directory")

        # If old photo is not empty, do motion detection
        if [ -n "$old_photo" ]; then
            if detect_motion "$old_photo" "$new_photo" "$motion_detection_script_location"; then
                save_motion_photo "$new_photo" "$destination_directory"
            fi
            rm "$old_photo"
            rm "${old_photo%.*}.json"
        fi

        old_photo="$new_photo"
        sleep "$photo_cooldown"

        # If amount_of_photos is not -1 (finite), decrement it
        if [ "$amount_of_photos" -ne -1 ]; then
            amount_of_photos=$((amount_of_photos - 1))
            # Break the loop if the number of photos reaches 0
            [ "$amount_of_photos" -eq 0 ] && break
        fi
    done
}

# Run main script
