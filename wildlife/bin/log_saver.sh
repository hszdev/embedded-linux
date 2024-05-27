#!/bin/bash


process_message() {
  local message="$1"
  local save_dir="$2"

  local time_now=$(date +"%Y-%m-%d %H:%M:%S.%N")
  local filename="${save_dir}/${time_now}.json"

  if [ -f "$filename" ]; then
    static counter=0  
    local new_filename="${filename%.*}_${counter}.json"
    while [ -f "$new_filename" ]; do
      ((counter++))
      new_filename="${filename%.*}_${counter}.json"
    done
    filename="$new_filename"
  fi

  echo "$message" > "$filename"
  echo "Saved message to: $filename"
}

usage(){
    echo "Usage: $0 <mqtt_broker> <mqtt_user> <mqtt_pass> <mqtt_topic> <save_dir>"
    echo "  - mqtt_broker: MQTT broker address"
    echo "  - mqtt_user: MQTT username"
    echo "  - mqtt_pass: MQTT password"
    echo "  - mqtt_topic: MQTT topic to subscribe to"
    echo "  - save_dir: Directory to save JSON files"
}

validate_input(){
    if [ $# -ne 5 ]; then
        echo "Error: Invalid number of arguments"
        usage
        exit 1
    fi
}


main() {
    local mqtt_broker="$1"
    local mqtt_user="$2"
    local mqtt_pass="$3"
    local mqtt_topic="$4"
    local save_dir="$5"

    validate_input "$@"
  


  mosquitto_sub -v -t "$mqtt_topic" -h "$mqtt_broker" -u "$mqtt_user" -P "$mqtt_pass" | while read -r message; do
    process_message "$message" "$save_dir"
  done
}

# Run the main function
main "$@"
