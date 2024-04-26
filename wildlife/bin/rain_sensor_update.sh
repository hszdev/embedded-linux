#!/bin/bash

# Serial port and MQTT broker details
SERIAL_PORT="/dev/ttyACM0"
BAUD_RATE="115200"
MQTT_BROKER="localhost"
MQTT_TOPIC="weather/rain_status"

# Function to publish message to MQTT
publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -t "$MQTT_TOPIC" -m "$1"
}

# Initialize serial communication with specified baud rate
stty -F $SERIAL_PORT $BAUD_RATE

# Initialize previous rain detection state
previous_rain_detect=0

# Continuously read from serial port
while read -r line; do
  # Parse JSON and extract 'rain_detect' value
  rain_detect=$(echo "$line" | jq -r '.rain_detect // empty')
  
  # Check for state change from not raining to raining
  if [[ "$rain_detect" == "1" && "$previous_rain_detect" == "0" ]]; then
    publish_mqtt "RAIN_START"
    previous_rain_detect=1
  elif [[ "$rain_detect" == "0" && "$previous_rain_detect" == "1" ]]; then
    publish_mqtt "RAIN_END"
    previous_rain_detect=0
  fi
done <"$SERIAL_PORT"

