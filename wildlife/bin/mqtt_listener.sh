#!/bin/bash
# Usage function
usage() {
    echo "Usage: $0 -h <mqtt_host> -p <mqtt_port> -u <username> -P <password> -t <topic>"
    echo "Example: $0 -h localhost -p 1883 -u esp -P 123 -t zigbee2mqtt/things/#"
    exit 1
}

while getopts "h:p:u:P:t:" opt; do
    case $opt in
        h) mqtt_host="$OPTARG" ;;
        p) mqtt_port="$OPTARG" ;;
        u) username="$OPTARG" ;;
        P) password="$OPTARG" ;;
        t) topic="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [ -z "$mqtt_host" ] || [ -z "$mqtt_port" ] || [ -z "$username" ] || [ -z "$password" ] || [ -z "$topic" ]; then
    usage
fi

# Main loop to reconnect when connection lost/broker unavailable
while true; do
    mosquitto_sub -h "$mqtt_host" -p "$mqtt_port" -u "$username" -P "$password" -t "$topic" -F "%t %p" | \
    while read -r payload; do
        # Here is the callback to execute whenever you receive a message:
        echo $(/home/emli/embedded-linux/wildlife/bin/take_photo.sh External "/home/emli/embedded-linux/wildlife/photos")
        echo "Extracted property: $p for $topic"
    done
    sleep 10  # Wait 10 seconds until reconnection
done

