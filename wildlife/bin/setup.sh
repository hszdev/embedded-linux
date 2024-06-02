#!/bin/bash

# Function to add cron jobs
setup_cronjobs() {
    local repo_dir="$1"
    ./cronjob_ctl.sh add "$repo_dir/wildlife/bin/take_photo.sh Time $repo_dir/wildlife/photos" '*/5 * * * *'
}

setup_services() {
    local repo_dir="$1"
    ./systemd_service_ctl.sh create "$repo_dir/wildlife/services"
}

# Function to remove cron jobs
remove_cronjobs() {
    local repo_dir="$1"
    ./cronjob_ctl.sh remove "$repo_dir/wildlife/bin/take_photo.sh Time $repo_dir/wildlife/photos" '*/5 * * * *'
}

remove_services() {
    local repo_dir="$1"
    ./systemd_service_ctl.sh delete "$repo_dir/wildlife/services"
}

# Main function
main() {
    local action="$1"
    local repo_dir="${2:-/home/emli/embedded-linux}"

    case "$action" in
        up)
            "$repo_dir/wildlife/bin/save_log.sh" "Setting up wildlife project"
            setup_cronjobs "$repo_dir"
            setup_services "$repo_dir"
            ;;
        down)
            "$repo_dir/wildlife/bin/save_log.sh" "Removing wildlife project"
            remove_cronjobs "$repo_dir"
            remove_services "$repo_dir"
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
