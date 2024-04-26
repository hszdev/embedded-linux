#!/bin/bash

# Serial port and MQTT broker details
SERIAL_PORT="/dev/ttyUSB0"
BAUD_RATE="115200"
MQTT_BROKER="localhost"
MQTT_TOPIC="weather/rain_status"

# Function to publish message to MQTT
publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -t "$MQTT_TOPIC" -m "$1"
}

# Initialize serial communication with specified baud rate
stty -F $SERIAL_PORT $BAUD_RATE

# Continuously read from serial port
while read -r line; do
  # Parse JSON and extract 'rain_detect' value
  rain_detect=$(echo "$line" | jq -r '.rain_detect // empty')
  if [[ "$rain_detect" == "1" ]]; then
    # It is raining, publish to MQTT
    publish_mqtt "RAIN DETECTED"
  fi
done <"$SERIAL_PORT"
