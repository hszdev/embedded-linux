#!/bin/bash
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

if [ -z "$mqtt_host" ] || [ -z "$mqtt_port" ] || [ -z "$username" ] || [ -z "$password" ] || [ -z "$topic" ]; then
    usage
fi

while true; do
	echo "Listening to messages"
    mosquitto_sub -h "$mqtt_host" -p "$mqtt_port" -u "$username" -P "$password" -t "$topic" -F "%t %p" | \
    while read -r payload; do
    	echo "Read payload"
        echo $(/home/emli/embedded-linux/wildlife/bin/take_photo.sh External "/home/emli/embedded-linux/wildlife/photos")
        echo "Extracted property: $p for $topic"
    done
    echo "Sleeping for 10"
    sleep 10
done

