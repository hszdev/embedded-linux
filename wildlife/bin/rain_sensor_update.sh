#!/bin/bash

# Serial port and MQTT broker details
SERIAL_PORT="/dev/ttyACM0"
BAUD_RATE="115200"
MQTT_BROKER="localhost"
RAIN_TOPIC="weather/rain_status"
WIPER_ANGLE_TOPIC="weather/wiper_angle"
MQTT_USER="esp"
MQTT_PASS="123"

# Function to publish message to MQTT with authentication
publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$RAIN_TOPIC" -m "$1" -r
}

write_latest_message() {
  # Subscribe to MQTT topic and read the latest message
  message=$(mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WIPER_ANGLE_TOPIC" -C 1)

  # Extract the wiper angle from the message
  angle=$(echo "$message" | jq -r '.wiper_angle')
  echo "message $message"

  # Validate the angle and send to serial port
  if [[ "$angle" =~ ^[0-9]+$ ]] && [ "$angle" -ge 0 ] && [ "$angle" -le 90 ]; then
    echo "{\"wiper_angle\": $angle}" > "$SERIAL_PORT"
  else
    echo "Received invalid angle: $angle"
  fi
}


# Initialize previous rain detection state
previous_rain_detect=0

# Continuously read from serial port
while true; do
  sleep 1 
  line=$(cat /dev/ttyACM0 | head -n 1)
  echo "Reading $line"

  # Parse JSON and extract 'rain_detect' value
  rain_detect=$(echo "$line" | jq -r '.rain_detect // empty')
  
  # Check for state change from not raining to raining
  echo "Changing state"
  if [[ "$rain_detect" == "1" && "$previous_rain_detect" == "0" ]]; then
    publish_mqtt "RAIN_START"
    previous_rain_detect=1
  elif [[ "$rain_detect" == "0" && "$previous_rain_detect" == "1" ]]; then
    publish_mqtt "RAIN_END"
    previous_rain_detect=0
  fi
  echo "Writing latest message"
  
done
