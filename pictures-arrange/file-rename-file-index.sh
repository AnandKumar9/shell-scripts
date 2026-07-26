#!/bin/zsh
#
# file-rename-file-index.sh
#
# Renames all files in a directory with sequential numeric indices while
# preserving their original extensions. Files are ordered by modification time
# (newest first), then renamed as 1.ext, 2.ext, 3.ext, etc.
#
# Usage:
#   ./file-rename-file-index.sh <folder-path> [start-number]
#
# Examples:
#   ./file-rename-file-index.sh ~/Pictures
#   ./file-rename-file-index.sh /path/to/photos 100
#   ./file-rename-file-index.sh ./downloads 1
#
# Arguments:
#   <folder-path>    - Directory containing files to rename
#   [start-number]   - Starting index number (default: 1)
#
# Result: Files renamed to sequential numbers with original extensions.
# Example: photo.jpg -> 1.jpg, IMG_123.png -> 2.png, etc.

dir="$1"
start="${2:-1}"   # if $2 not provided, default to 1
i=$start

setopt nullglob

files=("$dir"/*.(mov|mp4|MOV)(.om))
for ((idx=${#files[@]}; idx>=1; idx--)); do
  file="${files[idx]}"
  filename="${file:t}"
  ext="${filename:e}"
  printf -v newname "%d.%s" $i "$ext"
  mv "$file" "$dir/$newname"
  ((i++))
done