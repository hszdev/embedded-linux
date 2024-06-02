MQTT_BROKER="10.0.0.10"
WAITING_TOPIC="images/waiting"
DOWNLOADED_TOPIC="images/downloaded"
MQTT_USER="esp"
MQTT_PASS="123"
DOWNLOAD_URL="http://10.0.0.10:8099/images"



download_file() {
  local id="$1"
  local download_dir="$2"
  local json_file="$id.json"
  local image_file="$id.jpg"
  local drone_id="WILDDRONE-001"
  

  # Echo created URLS with image and json file
  echo "Downloading files for ID: $id"
  echo "Image URL: $DOWNLOAD_URL/$image_file"
  echo "JSON URL: $DOWNLOAD_URL/$json_file"

  wget -q -O "$download_dir/$image_file" "$DOWNLOAD_URL/$image_file"
  wget -q -O "$download_dir/$json_file" "$DOWNLOAD_URL/$json_file"

  # Verify both files exist
    if [ ! -f "$download_dir/$image_file" ] || [ ! -f "$download_dir/$json_file" ]; then
        echo "Error: Failed to download files for ID: $id"
        exit 1
    fi

  file_info=$(cat "$download_dir/$json_file")

  local seconds_epoch=$(date +%s.%N)
  local drone_copy_obj=$(jq -c -n --arg drone_id "$drone_id" --arg seconds_epoch "$seconds_epoch" '{ "Drone ID": $drone_id, "Seconds Epoch": $seconds_epoch }')
    
  # Append the new object to the original JSON and save it to file
  jq -c --argjson drone_copy "$drone_copy_obj" '. += { "Drone Copy": $drone_copy }' <<< "$file_info" > "$download_dir/$json_file"
  

  # Make JSON {id: id, Drone Copy: {Drone ID: drone_id, Seconds Epoch: seconds_epoch}} and send to MQTT
  message=$(jq -c -n --arg id "$id" --arg drone_id "$drone_id" --arg seconds_epoch "$seconds_epoch" '{id: $id, "Drone Copy": { "Drone ID": $drone_id, "Seconds Epoch": $seconds_epoch }}')
  publish_mqtt "$message"
  
  # Return drone_copy_obj for later use
  echo "$drone_copy_obj"
}


publish_mqtt() {
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$DOWNLOAD_TOPIC" -m "$1"
}



main() {
  local download_dir="$1"
  mosquitto_sub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$WAITING_TOPIC"  | while read -r message; do

    # Check if message is empty, whitespace, null or line break
    if [ -z "$message" ] || [ -z "$(echo -e "${message}" | tr -d '[:space:]')" ]; then
      echo "No more unread messages on MQTT topic: $topic"
    else
      echo "Message received: $message"
      echo "aaaa"

    jq -c '.[]' <<< "$message" | while read -r id; do
        echo "bbbb"
        # Remove quotes from ID
        id=$(sed -e 's/^"//' -e 's/"$//' <<<"$id")
        download_file "$id" "$download_dir"
        #jq -c --argjson drone_copy "$drone_copy_obj" '. += { "Drone Copy": $drone_copy }' <<< "$file_info"
    done

    fi
  done	
}

main "$@"
