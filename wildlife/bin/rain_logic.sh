#!/bin/bash

# MQTT Broker and Topic Settings
MQTT_BROKER="localhost"
RAIN_TOPIC="weather/rain_status"
WIPER_ANGLE_TOPIC="weather/wiper_angle"
MQTT_USER="esp"
MQTT_PASS="123"

# Function to publish angle to MQTT with authentication
publish_angle() {
    mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WIPER_ANGLE_TOPIC" -m "{\"wiper_angle\": $1}"
}

# Initial rain status is assumed not raining
is_raining=0

# Subscribe to rain status MQTT topic and handle messages with authentication
mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$RAIN_TOPIC" | while read -r message; do
    case "$message" in
        "RAIN_START")
            is_raining=1
            angle=0  # Start with angle at 0 when it begins to rain
            while [ "$is_raining" -eq 1 ]; do
                # Publish current angle
                publish_angle "$angle"

                # Alternate angle
                if [ "$angle" -eq 0 ]; then
                    angle=180
                else
                    angle=0
                fi

                sleep 1  # Wait for a second before changing the angle

                # Listen for a single message which might end the rain
                rain_message=$(mosquitto_sub -u "$MQTT_USER" -P "$MQTT_PASS" -h "$MQTT_BROKER" -t "$RAIN_TOPIC" -C 1)
                if [[ "$rain_message" == "RAIN_END" ]]; then
                    is_raining=0
                fi
            done
            ;;
        "RAIN_END")
            is_raining=0
            # Reset the wiper angle to 0 when rain ends
            publish_angle "0"
            ;;
    esac
done
