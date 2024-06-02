#!/bin/bash


usage() {
    echo "Usage: $0 <save_dir> <message>"
}

validate_input(){
    if [ $# -ne 2 ]; then
        echo "Error: Invalid number of arguments"
        usage
        exit 1
    fi
}


main() {
  validate_input "$@"
  local save_dir="$1"
  local message="$2"

  local time_now=$(date +"%Y-%m-%d %H:%M:%S.%N")
  local filename="${save_dir}/${time_now}.log"

  if [ -f "$filename" ]; then
    static counter=0  
    local new_filename="${filename%.*}_${counter}.log"
    while [ -f "$new_filename" ]; do
      ((counter++))
      new_filename="${filename%.*}_${counter}.log"
    done
    filename="$new_filename"
  fi

  echo "$message" > "$filename"
  echo "Saved message to: $filename"
}

main "$@"
