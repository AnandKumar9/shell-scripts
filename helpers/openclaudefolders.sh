#!/usr/bin/env zsh

# Opens configured Claude-related folders in Finder based on requested arguments. Look for
# folders under both the user's home directory and the current workspace.
#
# Examples:
#   openclaudefiles.sh skills
#   openclaudefiles.sh subagents rules
#   openclaudefiles.sh SKILLS SubAgents
#   openclaudefiles.sh skills junk rules
#   openclaudefiles.sh foo
#
# Notes:
#   - Matching is case-insensitive.
#   - Unknown arguments are ignored.
#   - At least one argument must be passed.
#   - At least one valid argument must be present.

readonly VALID_ARGUMENTS=(
  skills
  subagents
  rules
)

normalize_argument() {
  local candidate="$1"
  printf '%s\n' "${candidate:l}"
}

has_requested_argument() {
  local target="$1"
  shift
  local candidate

  for candidate in "$@"; do
    if [[ "$candidate" == "$target" ]]; then
      return 0
    fi
  done

  return 1
}

is_valid_argument() {
  local candidate
  candidate="$(normalize_argument "$1")"
  local valid_arg

  for valid_arg in "${VALID_ARGUMENTS[@]}"; do
    if [[ "$candidate" == "$valid_arg" ]]; then
      return 0
    fi
  done

  return 1
}

open_matching_claude_folders() {
  local label="$1"
  local relative_path="$2"
  local -a matching_folders=()
  local user_dir="$HOME/.claude/$relative_path"
  local workspace_dir="$PWD/.claude/$relative_path"
  local folder

  for folder in "$user_dir" "$workspace_dir"; do
    if [[ -d "$folder" ]]; then
      matching_folders+=("$folder")
    fi
  done

  if (( ${#matching_folders[@]} == 0 )); then
    echo "No matching folders (user or workspace) for $label"
    return 0
  fi

  open "${matching_folders[@]}"
}

handle_skills() {
  open_matching_claude_folders "skills" "skills"
}

handle_subagents() {
  open_matching_claude_folders "subagents" "agents"
}

handle_rules() {
  open_matching_claude_folders "rules" "rules"
}

main() {
  local original_arg_count=$#
  local -a requested_args=()
  local arg
  local valid_arg

  if (( original_arg_count == 0 )); then
    echo "At least one argument is required." >&2
    exit 1
  fi

  for arg in "$@"; do
    if is_valid_argument "$arg"; then
      requested_args+=("$(normalize_argument "$arg")")
    fi
  done

  if (( ${#requested_args[@]} == 0 )); then
    echo "No valid arguments were provided." >&2
    exit 1
  fi

  for valid_arg in "${VALID_ARGUMENTS[@]}"; do
    if ! has_requested_argument "$valid_arg" "${requested_args[@]}"; then
      continue
    fi

    case "$valid_arg" in
      skills)
        handle_skills
        ;;
      subagents)
        handle_subagents
        ;;
      rules)
        handle_rules
        ;;
    esac
  done
}

main "$@"
