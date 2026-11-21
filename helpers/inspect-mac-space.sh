#!/bin/zsh

# With no argument, inspect ~/Library and its descendants up to two levels deep.
# ~/Library/CloudStorage and its entire subtree are excluded. Show folders of at
# least 100 MB from that scan:
#   inspect-mac-space.sh
#
# Inspect a shortcut or a specific folder:
#   inspect-mac-space.sh Developer
#   inspect-mac-space.sh cache
#   inspect-mac-space.sh /path/to/folder
#
# Add -prompt before the optional path to number results and interactively delete
# selected folders. Deletions are permanent; enter q at the prompt to quit:
#   inspect-mac-space.sh -prompt
#   inspect-mac-space.sh -prompt Developer
#   inspect-mac-space.sh -prompt /path/to/folder
#
# ---- EXCLUDED FOLDERS ----
# ~/Library/CloudStorage and everything beneath it are always hidden and blocked
# from deletion.

# ---- WRITES LOGS ONCE A DAY ----
# A ~/Library scan (including -prompt with no path) is recorded at most once per
# calendar day in inspect-mac-space.log beside this script. The log has a TOTAL
# ~/Library section plus sections for results over 500 MB, with newest YYYY MM DD
# entries first.

# ---- PART OF launchd WORKFLOW ----
# This script is also a part of a launchd workflow with the config being in 
# `/Users/anandkumar/Library/LaunchAgents/com.anand.periodictask.plist`.
# To check if its still in launchd - launchctl list | grep com.anand.periodictask
# To remove it from launchd - launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.anand.periodictask.plist

prompt_for_deletion=0

if [[ $1 == -prompt ]]; then
  prompt_for_deletion=1
  target=${2:-$HOME/Library}
else
  target=${1:-$HOME/Library}
fi

case "${(L)target}" in
  developer) target=$HOME/Library/Developer ;;
  cache|caches) target=$HOME/Library/Caches ;;
esac

cloud_storage=$HOME/Library/CloudStorage
library=$HOME/Library
log_file=${0:A:h}/inspect-mac-space.log
target=${target:A}
cloud_storage=${cloud_storage:A}
library=${library:A}

if [[ $target == "$cloud_storage" || $target == "$cloud_storage"/* ]]; then
  print -u2 -r -- "Refusing to inspect CloudStorage or any folder inside it."
  exit 1
fi

results_file=$(mktemp -t inspect-mac-space) || exit 1
trap 'rm -f -- "$results_file"' EXIT INT TERM

scan() {
  du -h -d 2 -- "$target" 2>/dev/null |
    while IFS=$'\t' read -r size entry_path; do
      if [[ $entry_path == "$target" || $entry_path == "$target/" ]]; then
        entry_path=TOTAL
      fi
      print -r -- "$size"$'\t'"$entry_path"
    done |
    awk -F '\t' -v cloud="$cloud_storage" '
      $2 != cloud && index($2, cloud "/") != 1 {
        value = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        unit = substr(value, length(value), 1)
        number = value + 0
        multiplier = 1
        if (unit == "K") multiplier = 1024
        else if (unit == "M") multiplier = 1024 * 1024
        else if (unit == "G") multiplier = 1024 * 1024 * 1024
        else if (unit == "T") multiplier = 1024 * 1024 * 1024 * 1024
        if (number * multiplier >= 100 * 1024 * 1024) print
      }
    ' |
    awk -F '\t' '
      {
        paths[NR] = $2
        lines[NR] = $0
      }
      END {
        for (i = 1; i <= NR; i++) {
          redundant = 0
          if (paths[i] != "TOTAL") {
            prefix = paths[i] "/"
            for (j = 1; j <= NR; j++) {
              if (i != j && index(paths[j], prefix) == 1) {
                redundant = 1
                break
              }
            }
          }
          if (!redundant) print lines[i]
        }
      }
    ' |
    sort -hr >| "$results_file"
}

log_daily_library_snapshot() {
  [[ $target == "$library" ]] || return

  local today snapshot_file updated_log
  today=$(date '+%Y %m %d')

  # One snapshot covers every section, so any entry for today means this day's
  # scan has already been logged.
  if [[ -f $log_file ]] && awk -F '\t' -v date="$today" '$1 == date { found=1 } END { exit !found }' "$log_file"; then
    return
  fi

  snapshot_file=$(mktemp -t inspect-mac-space-snapshot) || return 1
  updated_log=$(mktemp -t inspect-mac-space-log) || {
    rm -f -- "$snapshot_file"
    return 1
  }
  [[ -f $log_file ]] || : >| "$log_file"

  awk -F '\t' '
    function bytes(value, unit, number, multiplier) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      unit = substr(value, length(value), 1)
      number = value + 0
      multiplier = 1
      if (unit == "K") multiplier = 1024
      else if (unit == "M") multiplier = 1024 * 1024
      else if (unit == "G") multiplier = 1024 * 1024 * 1024
      else if (unit == "T") multiplier = 1024 * 1024 * 1024 * 1024
      return number * multiplier
    }
    $2 == "TOTAL" { print "TOTAL ~/Library\t" $1; next }
    bytes($1) > 500 * 1024 * 1024 { print $2 "\t" $1 }
  ' "$results_file" >| "$snapshot_file"

  awk -F '\t' -v date="$today" '
    NR == FNR {
      value[$1] = $2
      order[++count] = $1
      next
    }
    /^## / {
      section = substr($0, 4)
      seen[section] = 1
      print
      if (section in value) print date "\t" value[section]
      next
    }
    { print }
    END {
      for (i = 1; i <= count; i++) {
        section = order[i]
        if (!(section in seen)) {
          if (NR > FNR || i > 1) print ""
          print "## " section
          print date "\t" value[section]
        }
      }
    }
  ' "$snapshot_file" "$log_file" >| "$updated_log"

  mv -f -- "$updated_log" "$log_file"
  rm -f -- "$snapshot_file"
}

while true; do
  scan
  log_daily_library_snapshot
  paths=()
  index=0

  print
  while IFS=$'\t' read -r size entry_path; do
    if [[ $entry_path == TOTAL ]]; then
      print -r -- "$size"$'\t'"TOTAL"
    else
      (( index++ ))
      paths+=("$entry_path")
      if (( prompt_for_deletion )); then
        printf '%d.\t%s\t%s\n' "$index" "$size" "$entry_path"
      else
        print -r -- "$size"$'\t'"$entry_path"
      fi
    fi
  done < "$results_file"

  if (( index == 0 )); then
    print -r -- "No folders of at least 100 MB remain."
    exit 0
  fi

  (( prompt_for_deletion )) || exit 0

  print -n -r -- "Index to permanently delete (or q to quit): "
  IFS= read -r choice || exit 0
  [[ ${(L)choice} == q ]] && exit 0

  if [[ $choice != <-> || $choice -lt 1 || $choice -gt $index ]]; then
    print -u2 -r -- "Invalid index; nothing was deleted."
    continue
  fi

  selected=${paths[$choice]}
  selected_real=${selected:A}

  if [[ $selected_real == "$cloud_storage" || $selected_real == "$cloud_storage"/* ]]; then
    print -u2 -r -- "BLOCKED: refusing to delete a CloudStorage path: $selected_real"
    continue
  fi

  if [[ ! -d $selected_real ]]; then
    print -u2 -r -- "Folder no longer exists; nothing was deleted: $selected_real"
    continue
  fi

  print -r -- "Deleting permanently: $selected_real"
  rm -rf -- "$selected_real"
done
