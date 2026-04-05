#!/bin/zsh

dir="$1"

for file in "$dir"/*; do
  [[ -f "$file" ]] || continue

  lat=$(exiftool -s3 -GPSLatitude "$file" | sed 's/ deg /° /')
  lon=$(exiftool -s3 -GPSLongitude "$file" | sed 's/ deg /° /')

  if [[ -n "$lat" && -n "$lon" ]]; then
    echo "$file  |  $lat , $lon"
  fi
done