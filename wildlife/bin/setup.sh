#!/bin/bash

# Function to add cron jobs
setup_cronjobs() {
    ./cronjob_ctl.sh add '/home/emli/wildlife/bin/take_photo.sh Time /home/emli/wildlife/photos' '*/5 * * * *'
    ./cronjob_ctl.sh add '/home/emli/wildlife/bin/motion_detection.sh /home/emli/wildlife/photos 120' '*/2 * * * *'
}

# Function to remove cron jobs
remove_cronjobs() {
    ./cronjob_ctl.sh remove '/home/emli/wildlife/bin/take_photo.sh Time /home/emli/wildlife/photos' '*/5 * * * *'
    ./cronjob_ctl.sh remove '/home/emli/wildlife/bin/motion_detection.sh /home/emli/wildlife/photos 120' '*/2 * * * *'
}

# Main function
main() {
    local action="$1"

    case "$action" in
        up)
            setup_cronjobs
            ;;
        down)
            remove_cronjobs
            ;;
        *)
            echo "Invalid action. Please specify 'up' or 'down'"
            exit 1
            ;;
    esac
}

# Usage
if [ $# -ne 1 ]; then
    echo "Usage: $0 <up/down>"
    echo "Example (up): $0 up"
    echo "Example (down): $0 down"
    exit 1
fi

main "$@"
