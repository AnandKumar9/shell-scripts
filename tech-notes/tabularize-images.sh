#!/usr/bin/env zsh

set -euo pipefail
setopt KSH_ARRAYS

# Check if argument is provided
if [[ $# -eq 0 ]]; then
  echo "No argument provided. Please provide a .md file path."
  exit 1
fi

md_file="$1"

# Check if the file exists
if [[ ! -f "$md_file" ]]; then
  echo "File does not exist: $md_file"
  exit 1
fi

# Extract all .png file references and list them with numbers
echo "Processing markdown file: $md_file"
echo ""
echo "PNG file references found:"

# Extract images with their original syntax
typeset -a image_filenames
typeset -a image_references

# Use Python to reliably extract references with original syntax
tmp_img_data=$(mktemp)
tmp_py=$(mktemp)
trap "rm -f $tmp_img_data $tmp_py" EXIT

cat > "$tmp_py" << 'PYTHON_SCRIPT'
import re
import sys

with open(sys.argv[1], 'r') as f:
    for line in f:
        if '|' in line:
            continue

        # Mark positions to exclude from plain text search
        excluded_pos = set()

        # Extract markdown images: ![alt](path.png)
        for match in re.finditer(r'!\[([^\]]*)\]\(([^)]*\.png)\)', line):
            full_ref = match.group(0)
            filename = match.group(2).split('/')[-1]
            print(f"{filename}\t{full_ref}")
            # Mark these positions as used
            for pos in range(match.start(), match.end()):
                excluded_pos.add(pos)

        # Extract links: [alt](path.png) - but NOT if preceded by !
        for match in re.finditer(r'(?<!\!)\[([^\]]*)\]\(([^)]*\.png)\)', line):
            full_ref = match.group(0)
            filename = match.group(2).split('/')[-1]
            print(f"{filename}\t{full_ref}")
            # Mark these positions as used
            for pos in range(match.start(), match.end()):
                excluded_pos.add(pos)

        # Extract plain .png references (not in brackets or already matched)
        for match in re.finditer(r'[a-zA-Z0-9_\.-]*\.png', line):
            start_pos = match.start()
            # Skip if this position was already matched above
            if start_pos in excluded_pos:
                continue
            bracket_count = line[:start_pos].count('[') - line[:start_pos].count(']')
            if bracket_count == 0 and not line[max(0,start_pos-1):start_pos] in ('!', '['):
                print(f"{match.group(0)}\t{match.group(0)}")
PYTHON_SCRIPT

python3 "$tmp_py" "$md_file" > "$tmp_img_data"

while IFS=$'\t' read -r filename reference; do
  if [[ -n "$filename" ]] && [[ -n "$reference" ]]; then
    image_filenames+=("$filename")
    image_references+=("$reference")
  fi
done < "$tmp_img_data"

# Display with numbers
for ((i=0; i<${#image_filenames[@]}; i++)); do
  echo "     $((i+1))	${image_filenames[$i]}"
done

echo ""
read -r "response?Put all of them in tables? (Y/range): "
response="${response:=Y}"

if [[ "$response" =~ ^[Yy]$ ]]; then
  table_range="all"
  echo "Proceeding to create tables for all images..."
elif [[ "$response" =~ ^[0-9]+-[0-9]+$ ]]; then
  start="${response%-*}"
  end="${response#*-}"
  table_range="$start-$end"
  echo "Proceeding to create tables for images $start through $end..."
fi

echo ""
read -r "columns?How many columns per table? (2/3): "
columns="${columns:=2}"

if [[ $columns -lt 2 ]]; then
  columns=2
elif [[ $columns -gt 3 ]]; then
  columns=3
fi

echo "Creating tables with $columns columns..."
echo ""

# Determine which images to tabularize
declare -a selected_references
if [[ "${table_range:-}" == "all" ]]; then
  selected_references=("${image_references[@]}")
else
  start=$((${table_range%-*} - 1))
  end=$((${table_range#*-} - 1))
  for ((i=start; i<=end; i++)); do
    if [[ $i -lt ${#image_references[@]} ]]; then
      selected_references+=("${image_references[$i]}")
    fi
  done
fi

# Create tables
table_content=""
total_images=${#selected_references[@]}
index=0

while [[ $index -lt $total_images ]]; do
  # Determine columns for this table
  remaining=$((total_images - index))
  if [[ $remaining -lt $columns ]]; then
    table_cols=$remaining
  else
    table_cols=$columns
  fi

  # Create header row (empty cells)
  header_row="|"
  for ((i=0; i<table_cols; i++)); do
    header_row+=" |"
  done
  table_content+="$header_row"$'\n'

  # Create separator row
  sep_row="|"
  for ((i=0; i<table_cols; i++)); do
    sep_row+="----|"
  done
  table_content+="$sep_row"$'\n'

  # Create image row
  img_row="|"
  for ((i=0; i<table_cols; i++)); do
    ref="${selected_references[$index]}"
    img_row+=" ${ref} |"
    index=$((index + 1))
  done
  table_content+="$img_row"$'\n'

  # Add spacing between tables if not the last one
  if [[ $index -lt $total_images ]]; then
    table_content+=$'\n'
  fi
done

# Remove original image references from file
tmp_cleaned=$(mktemp)
trap "rm -f $tmp_img_data $tmp_py $tmp_cleaned" EXIT

cat > "$tmp_py" << 'REMOVE_SCRIPT'
import re
import sys

# Get the list of references to remove
refs_to_remove = sys.argv[2:]
md_file = sys.argv[1]

with open(md_file, 'r') as f:
    lines = f.readlines()

# Process each line
output_lines = []
for line in lines:
    modified_line = line
    # Remove each reference from the line
    for ref in refs_to_remove:
        escaped_ref = re.escape(ref)
        modified_line = re.sub(escaped_ref, '', modified_line)

    # Clean up extra spaces
    modified_line = re.sub(r'  +', ' ', modified_line)
    modified_line = modified_line.strip()

    # Check if there's meaningful content left
    # Remove bullet/number patterns and whitespace to check
    content_check = re.sub(r'^[\d\.\-\*\+\s]+', '', modified_line)
    content_check = content_check.strip()

    # If there's meaningful content after cleanup, keep the line
    if content_check and not re.match(r'^[\.\-\*\+\s,;:]*$', content_check):
        output_lines.append(modified_line + '\n')
    # If it's just a bullet/number with nothing else, skip it

with open(md_file, 'w') as f:
    f.writelines(output_lines)
REMOVE_SCRIPT

python3 "$tmp_py" "$md_file" "${selected_references[@]}"

# Append tables to file with newline first
{
  echo ""
  echo "$table_content"
} >> "$md_file"
echo "Tables created and appended to $md_file"
