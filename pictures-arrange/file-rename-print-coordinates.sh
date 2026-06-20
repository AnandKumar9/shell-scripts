#!/bin/zsh
#
# file-rename-print-coordinates.sh
#
# Extracts and displays GPS coordinates from image EXIF metadata. Scans all
# files in a directory and prints latitude and longitude for images that contain
# geolocation data.
#
# Requires exiftool to be installed (brew install exiftool).
#
# Usage:
#   ./file-rename-print-coordinates.sh <folder-path>
#
# Examples:
#   ./file-rename-print-coordinates.sh ~/Pictures
#   ./file-rename-print-coordinates.sh /path/to/geotagged/photos
#   ./file-rename-print-coordinates.sh /Volumes/Camera/DCIM
#
# Output format:
#   /path/to/photo.jpg  |  40.7128° N , -74.0060° W
#
# Note: Only files with GPS metadata are displayed. Files without coordinates
# are silently skipped.

dir="$1"

for file in "$dir"/*; do
  [[ -f "$file" ]] || continue

  lat=$(exiftool -s3 -GPSLatitude "$file" | sed 's/ deg /° /')
  lon=$(exiftool -s3 -GPSLongitude "$file" | sed 's/ deg /° /')

  if [[ -n "$lat" && -n "$lon" ]]; then
    echo "$file  |  $lat , $lon"
  fi
done