#!/bin/bash

# Function to add cron jobs
setup_cronjobs() {
    local repo_dir="$1"
    ./cronjob_ctl.sh add "$repo_dir/wildlife/bin/take_photo.sh Time $repo_dir/wildlife/photos" '*/5 * * * *'
    ./cronjob_ctl.sh add "$repo_dir/wildlife/bin/motion_detection.sh $repo_dir/wildlife/photos 120" '*/2 * * * *'
}

# Function to remove cron jobs
remove_cronjobs() {
    local repo_dir="$1"
    ./cronjob_ctl.sh remove "$repo_dir/wildlife/bin/take_photo.sh Time $repo_dir/wildlife/photos" '*/5 * * * *'
    ./cronjob_ctl.sh remove "$repo_dir/wildlife/bin/motion_detection.sh $repo_dir/wildlife/photos 120" '*/2 * * * *'
}

# Main function
main() {
    local action="$1"
    local repo_dir="${2:-/home/emli/embedded-linux}"

    case "$action" in
        up)
            setup_cronjobs "$repo_dir"
            ;;
        down)
            remove_cronjobs "$repo_dir"
            ;;
        *)
            echo "Invalid action. Please specify 'up' or 'down'"
            exit 1
            ;;
    esac
}

# Usage
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <up/down> [repo_dir]"
    echo "Example (up): $0 up /path/to/repo"
    echo "Example (down): $0 down /path/to/repo"
    exit 1
fi

main "$@"
