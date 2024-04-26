#!/bin/bash

# Serial port and MQTT broker details
SERIAL_PORT="/dev/ttyACM0"
BAUD_RATE="115200"
MQTT_BROKER="localhost"
MQTT_TOPIC="weather/rain_status"
MQTT_USER="esp"
MQTT_PASS="123"

# Function to publish message to MQTT with authentication
publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$MQTT_TOPIC" -m "$1"
}

# Initialize serial communication with specified baud rate
#stty -F $SERIAL_PORT $BAUD_RATE

# Initialize previous rain detection state
previous_rain_detect=0




# Continuously read from serial port
while true; do
  sleep 1 
  line=$(cat /dev/ttyACM0 | head -n 1)
	# Output the current line
  echo "$line"  
  # Parse JSON and extract 'rain_detect' value
  rain_detect=$(echo "$line" | jq -r '.rain_detect // empty')
	echo "$rain_detect"
  
  # Check for state change from not raining to raining
  if [[ "$rain_detect" == "1" && "$previous_rain_detect" == "0" ]]; then
  	echo "start"
    publish_mqtt "RAIN_START"
    previous_rain_detect=1
  elif [[ "$rain_detect" == "0" && "$previous_rain_detect" == "1" ]]; then
  	echo "end"
    publish_mqtt "RAIN_END"
    previous_rain_detect=0
  fi
done
# <"$SERIAL_PORT"
