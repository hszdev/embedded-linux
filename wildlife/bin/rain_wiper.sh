#!/bin/bash

# Serial port and MQTT broker details
SERIAL_PORT="/dev/ttyACM0"
BAUD_RATE="115200"
MQTT_BROKER="localhost"
MQTT_TOPIC="weather/wiper_angle"
MQTT_USER="esp"
MQTT_PASS="123"

# Initialize serial communication with specified baud rate
#stty -F $SERIAL_PORT $BAUD_RATE cs8 -cstopb -ixon raw

# Subscribe to MQTT topic and read messages with authentication
mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$MQTT_TOPIC" | while read -r message; do
  # Extract the wiper angle from the message
  angle=$(echo "$message" | jq -r '.wiper_angle')
  echo "message $message"

  # Validate the angle and send to serial port
  if [[ "$angle" =~ ^[0-9]+$ ]] && [ "$angle" -ge 0 ] && [ "$angle" -le 180 ]; then
    echo "{\"wiper_angle\": $angle}" > "$SERIAL_PORT"
  else
    echo "Received invalid angle: $angle"
  fi
  sleep 1
done
