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
  local file_info="$1"
  local dir="$2"

    # Extract id and Drone Copy attributes
  id=$(jq -c -r '.id' <<< "$file_info")
  echo "updating $id"
  drone_copy=$(jq -c -r '.["Drone Copy"]' <<< "$file_info")

  # Update original JSON file with Drone Copy attribute
  echo "Before $(cat $dir/$id.json)"
  original_json_file="$dir/$id.json"
  jq -c --argjson drone_copy "$drone_copy" '. += { "Drone Copy": $drone_copy }' "$original_json_file" > "$original_json_file.tmp" && mv "$original_json_file.tmp" "$original_json_file" 
  echo "After $(cat $dir/$id.json)"

}


main() {
  local dir="$1"
  echo "Listenining"
  mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$DOWNLOADED_TOPIC"  | while read -r message; do
    if [ -z "$message" ]; then
      echo "No more unread messages on MQTT topic: $topic"
    else
      echo "Got a message: $message"
	  update_original_json "$message" "$dir"
    fi
  done	
}

main "$@"
