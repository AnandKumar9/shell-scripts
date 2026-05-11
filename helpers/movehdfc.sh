#!/usr/bin/env zsh

set -euo pipefail

DOWNLOADS_DIR="$HOME/Downloads"
TARGET_DIR="$HOME/Library/CloudStorage/GoogleDrive-write2anand.kumar@gmail.com/My Drive/Synced/Monetary/Credit Cards/HDFC Credit Card/Statements"

if [[ ! -d "$TARGET_DIR" ]]; then
  print "❌ Target directory does not exist: $TARGET_DIR"
  exit 1
fi

found_count=0
for file in "$DOWNLOADS_DIR"/5522*75_*_*.pdf; do
  [[ -f "$file" ]] || continue

  found_count=$((found_count + 1))
  filename=$(basename "$file")

  # Extract date: dd-mm-yyyy
  if [[ $filename =~ ([0-9]{2})-([0-9]{2})-([0-9]{4}) ]]; then
    day=$match[1]
    month=$match[2]
    year=$match[3]

    new_filename="HDFC statement $year $month $day.pdf"
    mv "$file" "$TARGET_DIR/$new_filename"
    print "✅ Moved: $new_filename"
  else
    print "❌ Could not parse date from: $filename"
  fi
done

if [[ $found_count -eq 0 ]]; then
  print "No matching files found in $DOWNLOADS_DIR"
fi
