#!/bin/bash

service_exists() {
  local service_name="$1"
  systemctl list-units --type=service | grep -q "$service_name.service"
}

# Function to process a service file (create or delete)
process_service() {
  local action="$1"
  local service_file="$2"

  # Extract service name from filename (assuming filename ends with '.service')
  local service_name="${service_file##*/}"
  service_name="${service_name%.service}"

  if [ "$action" == "create" ]; then
    create_service "$service_name" "$service_file"
  elif [ "$action" == "delete" ]; then
    delete_service "$service_name"
  else
    echo "Invalid action for service file '$service_file'."
    exit 1
  fi
}

create_service() {
  local service_name="$1"
  local service_file="$2"

  # Check if service file exists
  if [ ! -f "$service_file" ]; then
    echo "Error: Service file '$service_file' does not exist."
    exit 1
  fi

  # Check if service already exists
  if service_exists "$service_name"; then
    delete_service "$service_name"
  fi

  # Copy the service file to systemd directory
  sudo cp "$service_file" /etc/systemd/system/"$service_name.service"

  # Reload systemd and enable the service
  sudo systemctl daemon-reload
  sudo systemctl enable "$service_name.service"
  echo "Service '$service_name' created and enabled."
}

delete_service() {
  local service_name="$1"

  # Check if service exists
  if ! service_exists "$service_name"; then
    echo "Service '$service_name' does not exist."
    #return 1
  fi

  sudo systemctl disable "$service_name.service"
  sudo rm /etc/systemd/system/"$service_name.service"

  sudo systemctl daemon-reload
  echo "Service '$service_name' deleted."
}

# Function to manage all services in a directory
manage_services() {
  local action="$1"
  local service_dir="$2"

  # Check if directory exists and is readable
  if [ ! -d "$service_dir" ] || [ ! -r "$service_dir" ]; then
    echo "Error: Directory '$service_dir' does not exist or is not readable."
    exit 1
  fi

  # Loop through all files ending with '.service' in the directory
  for service_file in "$service_dir"/*.service; do
    process_service "$action" "$service_file"
  done
}

# Usage
if [ $# -lt 2 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <create/delete> <service_directory>"
  echo "  Example (create all): $0 create /path/to/services"
  echo "  Example (delete all): $0 delete /path/to/services"
  exit 1
fi

# Call manage_services with arguments
manage_services "$@"