#!/bin/zsh
#
# file-print-coordinates.sh
#
# Extracts and displays GPS coordinates from image EXIF metadata. Scans all
# files in a directory and prints latitude and longitude for images that contain
# geolocation data. Starting from the 2nd file, also displays the geometric
# distance in miles from the previous location.
#
# Requires exiftool to be installed (brew install exiftool).
#
# Usage:
#   ./file-print-coordinates.sh <folder-path>
#
# Examples:
#   ./file-print-coordinates.sh ~/Pictures
#   ./file-print-coordinates.sh /path/to/geotagged/photos
#   ./file-print-coordinates.sh /Volumes/Camera/DCIM
#
# Output format:
#   /path/to/photo.jpg  |  40° 42' 46.08" N , 74° 0' 21.60" W
#   /path/to/photo2.jpg  |  40° 51' 0.72" N , 74° 56' 56.76" W  |  XX.XX miles
#
# Note: Only files with GPS metadata are displayed. Files without coordinates
# are silently skipped. Distance calculations use the Haversine formula.

convert_dms_to_decimal() {
  local dms="$1"
  local direction="$2"

  local degrees=$(echo "$dms" | sed "s/°.*//" | xargs)
  local minutes=$(echo "$dms" | sed "s/.*° *//" | sed "s/' .*//" | xargs)
  local seconds=$(echo "$dms" | sed "s/.*' *//" | sed 's/".*//g' | xargs)

  local decimal=$(echo "scale=6; $degrees + $minutes/60 + $seconds/3600" | bc)

  if [[ "$direction" == "S" || "$direction" == "W" ]]; then
    decimal=$(echo "scale=6; -1 * $decimal" | bc)
  fi

  echo "$decimal"
}

calculate_distance() {
  local lat1="$1"
  local lon1="$2"
  local lat2="$3"
  local lon2="$4"

  local lat1_rad=$(echo "scale=6; $lat1 * 3.141592653589793 / 180" | bc)
  local lon1_rad=$(echo "scale=6; $lon1 * 3.141592653589793 / 180" | bc)
  local lat2_rad=$(echo "scale=6; $lat2 * 3.141592653589793 / 180" | bc)
  local lon2_rad=$(echo "scale=6; $lon2 * 3.141592653589793 / 180" | bc)

  local dlat=$(echo "scale=6; $lat2_rad - $lat1_rad" | bc)
  local dlon=$(echo "scale=6; $lon2_rad - $lon1_rad" | bc)

  local a=$(echo "scale=10; s($dlat/2)^2 + c($lat1_rad) * c($lat2_rad) * s($dlon/2)^2" | bc -l)
  local c=$(echo "scale=10; 2 * a(sqrt($a) / sqrt(1-$a))" | bc -l)

  local earth_radius=3959
  local distance=$(echo "$earth_radius * $c" | bc -l)

  printf "%.2f" "$distance"
}

dir="$1"
prev_lat_decimal=""
prev_lon_decimal=""

for file in "$dir"/*; do
  [[ -f "$file" ]] || continue

  lat=$(exiftool -s3 -GPSLatitude "$file" | sed 's/ deg /° /')
  lon=$(exiftool -s3 -GPSLongitude "$file" | sed 's/ deg /° /')

  if [[ -n "$lat" && -n "$lon" ]]; then
    local lat_dir=$(echo "$lat" | grep -o '[NS]$')
    local lon_dir=$(echo "$lon" | grep -o '[EW]$')

    local lat_dms=$(echo "$lat" | sed 's/ [NS]$//')
    local lon_dms=$(echo "$lon" | sed 's/ [EW]$//')

    local lat_decimal=$(convert_dms_to_decimal "$lat_dms" "$lat_dir")
    local lon_decimal=$(convert_dms_to_decimal "$lon_dms" "$lon_dir")

    if [[ -n "$prev_lat_decimal" && -n "$prev_lon_decimal" ]]; then
      local distance=$(calculate_distance "$prev_lat_decimal" "$prev_lon_decimal" "$lat_decimal" "$lon_decimal")
      echo "$file  |  $lat , $lon  |  $distance miles"
    else
      echo "$file  |  $lat , $lon"
    fi

    prev_lat_decimal="$lat_decimal"
    prev_lon_decimal="$lon_decimal"
  fi
done