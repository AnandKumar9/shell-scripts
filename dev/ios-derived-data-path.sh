#!/bin/zsh
#
# ios-derived-data-path.sh
#
# Finds and displays the build directory (BUILD_DIR) for an iOS/macOS Xcode project
# or workspace. Automatically opens the build directory in Finder. The concerned 
# project/xcworkspace and scheme can be passed as command-line arguments, otherwise
# the script tries to automatically detect it based on current working directory.
#
# Usage:
#   ./ios-derived-data-path.sh [.xcodeproj or .xcworkspace path] [-scheme scheme-name]
#
# Examples:
#   ./ios-derived-data-path.sh   <---- Auto-detect project and scheme in current directory
#   ./ios-derived-data-path.sh ~/MyApp.xcodeproj   <---- Specify a project
#   ./ios-derived-data-path.sh ~/MyApp.xcworkspace -scheme MyScheme   <---- Specify a workspace and scheme
#   ./ios-derived-data-path.sh ~/MyApp.xcworkspace   <---- Specify just the workspace (auto-detect scheme if only one)
#
# xcodebuild Commands Used:
#   1. xcodebuild -project/-workspace <path> -list
#      Used to fetch available schemes in the project/workspace
#      Filtered with awk and grep to extract scheme name
#
#   2. xcodebuild -project/-workspace <path> -scheme <name> -showBuildSettings
#      Used to fetch all build settings for the given scheme
#      Filtered with grep to extract BUILD_DIR value
#
# Behavior:
#   - If no project path is provided, searches for a single .xcworkspace or .xcodeproj
#     in the current directory. Fails if none or multiple are found.
#   - If no scheme is specified, queries xcodebuild for available schemes. Fails if
#     there are zero or multiple schemes.
#   - Prints the BUILD_DIR path to stdout
#   - Automatically opens the directory in Finder
#
# Errors:
#   - Exits with error if multiple projects/workspaces or schemes are found
#   - Exits with error if BUILD_DIR cannot be determined

set -euo pipefail

PROJECT_OR_WORKSPACE="${1:-}"

# Step 1: Identify the project
if [[ -z "$PROJECT_OR_WORKSPACE" ]]; then
  # Search for .xcworkspace or .xcodeproj in current director
  workspaces=($(find . -maxdepth 1 -name "*.xcworkspace" -type d))
  projects=($(find . -maxdepth 1 -name "*.xcodeproj" -type d))

  if (( ${#workspaces[@]} > 1 )); then
    echo "Error: Multiple .xcworkspace found in current directory" >&2
    exit 1
  elif (( ${#projects[@]} > 1 )); then
    echo "Error: Multiple .xcodeproj found in current directory" >&2
    exit 1
  elif (( ${#workspaces[@]} == 1 )); then
    PROJECT_OR_WORKSPACE="${workspaces[1]}"
  elif (( ${#projects[@]} == 1 )); then
    PROJECT_OR_WORKSPACE="${projects[1]}"
  else
    echo "Error: No .xcodeproj or .xcworkspace found in current directory" >&2
    exit 1
  fi
fi

# Validate that the provided/found project or workspace exists
if [[ ! -e "$PROJECT_OR_WORKSPACE" ]]; then
  echo "Error: '$PROJECT_OR_WORKSPACE' does not exist" >&2
  exit 1
fi

# Validate that it's actually a .xcodeproj or .xcworkspace
if [[ ! "$PROJECT_OR_WORKSPACE" =~ \.(xcodeproj|xcworkspace)$ ]]; then
  echo "Error: '$PROJECT_OR_WORKSPACE' is not a .xcodeproj or .xcworkspace" >&2
  exit 1
fi

# Step 2: Identify the scheme
SCHEME=""

# Check if -scheme was passed with a value
for (( i=2; i<=$#; i++ )); do
  if [[ "${@[$i]}" == "-scheme" ]]; then
    (( i++ ))
    if (( i <= $# )); then
      SCHEME="${@[$i]}"
    fi
    break
  fi
done

# If no scheme was passed, get it from xcodebuild
if [[ -z "$SCHEME" ]]; then
  local list_arg=""
  if [[ "$PROJECT_OR_WORKSPACE" =~ \.xcodeproj$ ]]; then
    list_arg="-project"
  else
    list_arg="-workspace"
  fi

  schemes=$(xcodebuild "$list_arg" "$PROJECT_OR_WORKSPACE" -list 2>/dev/null | awk '/Schemes:/{flag=1;next}/^$/&&flag{exit}flag' | grep -v '^[[:space:]]*$' | xargs)

  scheme_array=(${(s: :)schemes})

  if (( ${#scheme_array[@]} == 0 )); then
    echo "Error: No schemes found in '$PROJECT_OR_WORKSPACE'" >&2
    exit 1
  elif (( ${#scheme_array[@]} > 1 )); then
    echo "Error: Multiple schemes found in '$PROJECT_OR_WORKSPACE'. Please specify one with -scheme:" >&2
    for scheme in "${scheme_array[@]}"; do
      echo "  - $scheme" >&2
    done
    exit 1
  fi

  SCHEME="${scheme_array[1]}"
fi

# Step 3: Get BUILD_DIR using xcodebuild
local list_arg=""
if [[ "$PROJECT_OR_WORKSPACE" =~ \.xcodeproj$ ]]; then
  list_arg="-project"
else
  list_arg="-workspace"
fi

BUILD_DIR=$(xcodebuild "$list_arg" "$PROJECT_OR_WORKSPACE" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "^[[:space:]]*BUILD_DIR = " | awk -F'= ' '{print $2}')

if [[ -z "$BUILD_DIR" ]]; then
  echo "ERROR ----------> Could not determine BUILD_DIR for scheme '$SCHEME'" >&2
  exit 1
fi

if [[ -d "$BUILD_DIR" ]]; then
  open "$BUILD_DIR"
  if [[ "$BUILD_DIR" =~ DerivedData ]]; then
    echo "DERIVED DATA  ----------> DerivedData/${BUILD_DIR##*DerivedData/}"
  else
    echo "DERIVED DATA  ----------> $BUILD_DIR"
  fi
else
  echo "ERROR ----------> Expected Derived data folder path does not exist: $BUILD_DIR" >&2
  exit 1
fi
