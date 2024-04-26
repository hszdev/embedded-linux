#!/bin/bash

# Check if the image path is provided as a parameter
if [ $# -eq 0 ]; then
  echo "Please provide the image path as a parameter."
  exit 1
fi

# Get the image path and sidecar path
image_path=$1
sidecar_path="${image_path%.*}.json"

# Check if the image and sidecar file exists
if [ ! -f $image_path ]; then
  echo "The image file does not exist."
  exit 1
fi

if [ ! -f $sidecar_path ]; then
  echo "The sidecar file does not exist."
  exit 1
fi

# Get the image annotation
image_annotation=$(ollama run llava:7b "list the animals in the image $image_path")

# Append the image annotation to the sidecar file in JSON format by removing the last '}' character and adding the annotation
sed -i '$ s/.$//' $sidecar_path
echo ",\"annotation\":\"$image_annotation\"}" >> $sidecar_path