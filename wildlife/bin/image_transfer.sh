#!/bin/bash
MQTT_BROKER="localhost"
WAITING_TOPIC="images/waiting"
DOWNLOADED_TOPIC="images/downloaded"
MQTT_USER="esp"
MQTT_PASS="123"

check_json_files() {
  local dir="$1"

  # Find JSON files and extract parent directories
  paths=$(find "$dir" -mindepth 2 -maxdepth 2 -name '*.json' -exec grep -L '"Drone Copy"' {} + | awk -F/ '{ print $(NF-1) "/" $NF }' | sed 's/.json$//')

  # Convert paths to JSON array
  if [ -n "$paths" ]; then
    echo "$paths" | jq -c -R . | jq -c -s 'map(.)'
  else
    echo "[]"
  fi
}




publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WAITING_TOPIC" -m "$1"
}

convert_waiting_files() {
  local waiting_files="$1"

  drone_copy_obj='{ "Drone ID": "WILDDRONE-001", "Seconds Epoch": 17132712340.458 }'

  local converted_json=$(jq -c --argjson drone_copy "$drone_copy_obj" '[ .[] | {id: ., "Drone Copy": $drone_copy } ]' <<< "$waiting_files")

  echo "$converted_json"
}


filter_waiting_files() {
  local json="$1"
  local waiting_files="$2"
  jq -c --argjson waiting_files "$waiting_files" 'map(select(.id | IN($waiting_files[])))' <<< "$json"
}

update_original_json() {
  local filtered_json="$1"
  local dir="$2"

  jq -c '.[]' <<< "$filtered_json" | while read -r file_info; do
    # Extract id and Drone Copy attributes
    id=$(jq -c -r '.id' <<< "$file_info")
    echo "updating $id"
    drone_copy=$(jq -c -r '.["Drone Copy"]' <<< "$file_info")

    # Update original JSON file with Drone Copy attribute
    original_json_file="$dir/$id.json"
    echo $(jq -c --arg drone_copy "$drone_copy" '. += { "Drone Copy": $drone_copy }' "$original_json_file")
    jq -c --arg drone_copy "$drone_copy" '. += { "Drone Copy": $drone_copy }' "$original_json_file" > "$original_json_file.tmp" && mv "$original_json_file.tmp" "$original_json_file"
  done
}


main() {
  local dir="$1"
  local waiting_files=$(check_json_files "$dir")	
  update_waiting_files() {
    while true; do
      sleep 1
      waiting_files=$(check_json_files "$dir")
      sleep 1
      local converted=$(convert_waiting_files "$waiting_files")
      publish_mqtt "$converted"
    done
  }
  update_waiting_files &

  
  mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WAITING_TOPIC"  | while read -r message; do
    if [ -z "$message" ]; then
      echo "No more unread messages on MQTT topic: $topic"
      #Do logic with updated waiting_files
    else
    echo
    echo
    echo "Message: $message"
    echo "Waiting list: $waiting_files"
	filtered_json=$(filter_waiting_files "$message" "$waiting_files")
	echo "Filtered: $filtered_json"
	echo
	echo
	echo
	update_original_json "$filtered_json" "$dir"
    fi
  done	
}

main "$@"
