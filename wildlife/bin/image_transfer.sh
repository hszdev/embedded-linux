#!/bin/bash
MQTT_BROKER="localhost"
WAITING_TOPIC="images/waiting"
DOWNLOADED_TOPIC="images/downloaded"
MQTT_USER="esp"
MQTT_PASS="123"

check_json_files() {
  local dir="$1"

  paths=$(find "$dir" -mindepth 2 -maxdepth 2 -name '*.json' -exec grep -L '"Drone Copy"' {} + | awk -F/ '{ print $(NF-1) "/" $NF }' | sed 's/.json$//')

  if [ -n "$paths" ]; then
    echo "$paths" | jq -c -R . | jq -c -s 'map(.)'
  else
    echo "[]"
  fi
}


publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WAITING_TOPIC" -m "$1"
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
    jq -c --arg drone_copy "$drone_copy" '. += { "Drone Copy": $drone_copy }' "$original_json_file" > "$original_json_file.tmp" && mv "$original_json_file.tmp" "$original_json_file"
  done
}


main() {
  local dir="$1"
  local waiting_files=$(check_json_files "$dir")	
  
  update_waiting_files() {
    while true; do
      sleep 2
      waiting_files=$(check_json_files "$dir")
      local converted=$(convert_waiting_files "$waiting_files")
      publish_mqtt "$waiting_files"
    done
  }
  update_waiting_files &

  mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$DOWNLOADED_TOPIC"  | while read -r message; do
    if [ -z "$message" ]; then
      echo "No more unread messages on MQTT topic: $topic"
    else
	filtered_json=$(filter_waiting_files "$message" "$waiting_files")
	update_original_json "$filtered_json" "$dir"
    fi
  done	
}

main "$@"
