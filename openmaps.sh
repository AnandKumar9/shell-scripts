#!/usr/bin/env zsh

TARGET_DIR="/Users/anandkumar/Library/CloudStorage/GoogleDrive-write2anand.kumar@gmail.com/My Drive/Synced/Misc./Maps/"

QUERY="$*"

# If no arguments, open the folder
if [[ -z "$QUERY" ]]; then
  open "$TARGET_DIR"
  exit 0
fi

# Find matching files (case-insensitive)
matches=("${(@f)$(ls -1 "$TARGET_DIR" | grep -i -- "$QUERY")}")

# Exactly one match → open it
if (( ${#matches} == 1 )); then
  open "$TARGET_DIR/${matches[1]}"
else
  # zero or multiple matches → open folder
  open "$TARGET_DIR"
fi
