#!/bin/zsh
#
# file-rename-change-extension-case.sh
#
# Converts uppercase video file extensions to lowercase. Renames all .MOV files
# to .mov in the specified directory.
#
# Useful for standardizing video file extensions, particularly for videos from
# Apple devices that use .MOV format.
#
# Usage:
#   ./file-rename-change-extension-case.sh [folder-path]
#
# Examples:
#   ./file-rename-change-extension-case.sh ~/Videos
#   ./file-rename-change-extension-case.sh .
#   ./file-rename-change-extension-case.sh /Volumes/iPhone\ Photos
#
# If no folder is provided, defaults to current directory (.).
#
# Result: All .MOV files renamed to .mov in the target folder.

dir="${1:-.}"

for file in "$dir"/*.MOV(.); do
  mv "$file" "${file:r}.mov"
done