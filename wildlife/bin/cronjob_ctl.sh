#!/bin/bash

# Function to check if a cron job exists
cronjob_exists() {
    local command="$1"
    crontab -l | grep -q "$command"
}

# Function to add a cron job
add_cronjob() {
    local command="$1"
    local schedule="$2"
	(crontab -l ; echo "$schedule $command") | crontab -    
}

# Function to remove a cron job
remove_cronjob() {
    local command="$1"
    # Remove all cron jobs matching the specified command
    crontab -l | sed "/$command/d" | crontab -
}

# Function for adding or removing cron job based on the action
manage_cronjob() {
    local action="$1"
    local command="$2"
    local schedule="$3"

    if [ "$action" == "add" ]; then
        if cronjob_exists "$command"; then
            echo "Cron job already exists"
        else
            add_cronjob "$command" "$schedule"
            echo "Cron job added successfully"
        fi
    elif [ "$action" == "remove" ]; then
        if cronjob_exists "$command"; then
            remove_cronjob "$command"
            echo "Cron job removed successfully"
        else
            echo "Cron job does not exist"
        fi
    else
        echo "Invalid action. Please specify 'add' or 'remove'"
        exit 1
    fi
}

# Usage
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <add/remove> <command> <schedule>"
    echo "	Example (add): $0 add '/path/to/script.sh' '0 0 * * *'"
    echo "	Example (remove): $0 remove '/path/to/script.sh'"
    exit 1
fi

manage_cronjob "$@"
