#!/bin/bash

venv_exists() {
  local venv_dir="$1"
  [ -d "$venv_dir" ] && source "$venv_dir/bin/activate" && return 0
  return 1
}

create_venv() {
  local venv_dir="$1"
  if ! venv_exists "$venv_dir"; then
    echo "Creating virtual environment '$venv_dir'..."
    python3 -m venv "$venv_dir"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create virtual environment."
      exit 1
    fi
    source "$venv_dir/bin/activate"
  fi
}

verify_dependencies() {
  local requirements_file="$1"
  if [ ! -f "$requirements_file" ]; then
    echo "Error: Requirements file '$requirements_file' not found."
    exit 1
  fi
  pip install -r "$requirements_file" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install dependencies from '$requirements_file'."
    exit 1
  fi
}

venv_dir=".venv"
requirements_file="requirements.txt"

if [ $# -lt 5 ]; then
  echo "Usage: $0 <working_directory> <python_script> <image_folder> <host> <port>"
  echo "  - working_directory: Path to the directory containing the script and virtual environment."
  echo "  - python_script: Name of the Python script to execute."
  echo "  - image_folder: Path to the folder containing images (for wildlife script)."
  echo "  - host: Host address to bind the application (for wildlife script)."
  echo "  - port: Port number to listen on (for wildlife script)."
  exit 1
fi

working_dir="$1"
script_name="$2"
image_folder="$3"
host="$4"
port="$5"

cd "$working_dir" || {
  echo "Error: Could not change directory to '$working_dir'."
  exit 1
}

full_venv_dir="$working_dir/$venv_dir"
full_requirements_file="$working_dir/$requirements_file"

create_venv "$full_venv_dir"
verify_dependencies "$full_requirements_file"

python3 "$script_name" "--folder" "$image_folder" "--host" "$host" "--port" "$port" "--debug"

