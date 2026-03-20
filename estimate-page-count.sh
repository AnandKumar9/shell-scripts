#!/bin/zsh

# Usage:
#   <scritptName> /path/to/folder
#
# Assumptions:
# - Markdown is rendered to a text-like page layout
# - Prose wraps at ~78 chars
# - Lists wrap a bit narrower
# - Code blocks wrap less aggressively
# - About 50 rendered lines per printed page

dir="${1:-.}"

prose_width=78
list_width=72
code_width=88
lines_per_page=50

total_pages=0
total_lines=0
file_output=()

estimate_file() {
  local file="$1"

  awk -v prose_width="$prose_width" \
      -v list_width="$list_width" \
      -v code_width="$code_width" '
  function ceil(x) { return (x == int(x)) ? x : int(x) + 1 }

  function wrapped_lines(text_len, width) {
    if (text_len <= 0) return 1
    return ceil(text_len / width)
  }

  BEGIN {
    in_code = 0
    total = 0
  }

  {
    line = $0

    # fenced code block start/end
    if (line ~ /^```/ || line ~ /^~~~/) {
      in_code = !in_code
      total += 1
      next
    }

    # inside code block
    if (in_code) {
      len = length(line)
      total += wrapped_lines(len, code_width)
      next
    }

    # blank line
    if (line ~ /^[[:space:]]*$/) {
      total += 1
      next
    }

    # horizontal rule
    if (line ~ /^[[:space:]]*([-*_][[:space:]]*){3,}$/) {
      total += 2
      next
    }

    # ATX heading: #, ##, ###...
    if (line ~ /^#{1,6}[[:space:]]+/) {
      level = match(line, /[^#]/) - 1
      if (level <= 0) level = 1
      len = length(line)
      # bigger headings take a bit more vertical space
      extra = (level == 1 ? 3 : (level == 2 ? 2 : 1))
      total += wrapped_lines(len, prose_width) + extra
      next
    }

    # blockquote
    if (line ~ /^[[:space:]]*>[[:space:]]?/) {
      len = length(line)
      total += wrapped_lines(len, prose_width - 4) + 1
      next
    }

    # unordered / ordered list item
    if (line ~ /^[[:space:]]*([-*+]|[0-9]+\.)[[:space:]]+/) {
      len = length(line)
      total += wrapped_lines(len, list_width)
      next
    }

    # markdown image
    if (line ~ /!\[[^]]*\]\([^)]+\)/) {
      # fixed estimate for a medium image and caption spacing
      total += 12
      next
    }

    # table row
    if (line ~ /\|/) {
      # tables usually print less compactly than raw text
      total += 2
      next
    }

    # indented code block
    if (line ~ /^(    |\t)/) {
      len = length(line)
      total += wrapped_lines(len, code_width)
      next
    }

    # normal paragraph text
    len = length(line)
    total += wrapped_lines(len, prose_width)
  }

  END {
    print total
  }' "$file"
}

dir_name=${PWD:t}

while IFS= read -r -d '' file; do
  rendered_lines=$(estimate_file "$file")
  pages=$(( (rendered_lines + lines_per_page - 1) / lines_per_page ))

  file_display=${file#./}
  file_output+=("$(printf '%-36s %6d pages' "$file_display" "$pages")")

  total_lines=$((total_lines + rendered_lines))
  total_pages=$((total_pages + pages))
done < <(find "$dir" -type f -name "*.md" -print0 | sort -z)

echo "\nDirectory: ${dir_name:u}"
echo "Total Estimated Pages: $total_pages\n"
printf '%s\n' "${file_output[@]}"
