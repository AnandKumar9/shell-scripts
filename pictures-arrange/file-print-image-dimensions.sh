#!/bin/zsh

set -u

if [[ $# -ne 1 ]]; then
  print -u2 "Usage: $0 <folder-path>"
  exit 1
fi

folder_path=${1:A}

if [[ ! -d "$folder_path" ]]; then
  print -u2 "Error: '$folder_path' is not a directory."
  exit 1
fi

setopt null_glob

image_files=(
  "$folder_path"/*.(heic|HEIC|png|PNG|jpeg|JPEG|jpg|JPG)
)

if (( ${#image_files} == 0 )); then
  print "No supported image files found in: $folder_path"
  exit 0
fi

unique_destination_path() {
  local destination_dir=$1
  local original_name=$2
  local base_name=${original_name:r}
  local extension=${original_name:e}
  local candidate_path="$destination_dir/$original_name"
  local counter=1

  while [[ -e "$candidate_path" ]]; do
    if [[ -n "$extension" ]]; then
      candidate_path="$destination_dir/${base_name}-$counter.$extension"
    else
      candidate_path="$destination_dir/${base_name}-$counter"
    fi
    ((counter++))
  done

  print -- "$candidate_path"
}

read_dimensions() {
  local image_file=$1
  local pixel_width
  local pixel_height

  pixel_width=$(mdls -raw -name kMDItemPixelWidth "$image_file" 2>/dev/null)
  pixel_height=$(mdls -raw -name kMDItemPixelHeight "$image_file" 2>/dev/null)

  if [[ -z "$pixel_width" || -z "$pixel_height" || "$pixel_width" == "(null)" || "$pixel_height" == "(null)" ]]; then
    pixel_width=$(sips -g pixelWidth "$image_file" 2>/dev/null | awk '/pixelWidth:/ {print $2}')
    pixel_height=$(sips -g pixelHeight "$image_file" 2>/dev/null | awk '/pixelHeight:/ {print $2}')
  fi

  if [[ -n "$pixel_width" && -n "$pixel_height" ]]; then
    print -- "${pixel_width}:${pixel_height}"
    return 0
  fi

  return 1
}

for image_file in "${image_files[@]}"; do
  dimensions=$(read_dimensions "$image_file")
  if [[ $? -ne 0 ]]; then
    print -u2 "Failed to read dimensions for: $image_file"
    continue
  fi

  pixel_width=${dimensions%%:*}
  pixel_height=${dimensions##*:}

  dimension_folder="$folder_path/${pixel_width}x${pixel_height}"
  mkdir -p "$dimension_folder"

  destination_path=$(unique_destination_path "$dimension_folder" "${image_file:t}")
  mv "$image_file" "$destination_path"

  print "${image_file:t} -> ${pixel_width}x${pixel_height}/"
done
