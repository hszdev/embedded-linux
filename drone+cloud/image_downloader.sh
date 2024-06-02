MQTT_BROKER="10.0.0.10"
DOWNLOAD_TOPIC="images/downloaded"
MQTT_USER="esp"
MQTT_PASS="123"
DOWNLOAD_URL="http://10.0.0.10:8099/images"
WAITING_URL="http://10.0.0.10:8099/waiting"


download_file() {
  local id="$1"
  local download_dir="$2"
  local json_file="$id.json"
  local image_file="$id.jpg"
  local drone_id="WILDDRONE-001"
  local dir_from_id="${id:0: -10}"

  # Echo created URLS with image and json file
  echo "Downloading files for ID: $id"
  echo "Image URL: $DOWNLOAD_URL/$image_file"
  echo "JSON URL: $DOWNLOAD_URL/$json_file"
  
  
  echo "Creating download directory: $dir_from_id"
  mkdir -p "$download_dir/$dir_from_id" 
  wget -q -O "$download_dir/$image_file" "$DOWNLOAD_URL/$image_file"
  wget -q -O "$download_dir/$json_file" "$DOWNLOAD_URL/$json_file"
  
  # Verify both files exist
  echo "Verifying downloaded files"
  if [ ! -f "$download_dir/$image_file" ] || [ ! -f "$download_dir/$json_file" ]; then
      echo "Error: Failed to download files for ID: $id"
      exit 1
  fi

  echo "Files downloaded successfully"
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
  echo "Publishing message to topic: $DOWNLOAD_TOPIC, message: $1"
  mosquitto_pub -h "$MQTT_BROKER" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$DOWNLOAD_TOPIC" -m "$1"
}



main() {
  local download_dir="$1"
  local processing_array=()

  while true; do
    sleep 2
    echo "Checking for new messages on url: $WAITING_URL"

    # Query waiting url to get array of ids
    message=$(wget -q -O - "$WAITING_URL")
    if [ -z "$message" ]; then
      echo "No more unread messages on MQTT topic: $topic"
      break
    fi


    # Filter to only 100

    echo "Processing message: $message"

    jq -c '.[]' <<< "$message" | while read -r id; do
        id=$(sed -e 's/^"//' -e 's/"$//' <<<"$id")

        # Check if id is already being processed
        if [[ " ${processing_array[@]} " =~ " ${id} " ]]; then
            echo "ID: $id is already being processed"
            continue
        fi

        processing_array+=("$id")
        echo "$id"
        download_file "$id" "$download_dir"
        #jq -c --argjson drone_copy "$drone_copy_obj" '. += { "Drone Copy": $drone_copy }' <<< "$file_info"
    done


  done
}

main "$@"
