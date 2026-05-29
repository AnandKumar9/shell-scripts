#!/bin/zsh
#
# iOS Simulator Sandbox Path Inspector
#
# Usage:
#   ./ios-sandbox-path.sh          # Browse installed third-party apps
#   ./ios-sandbox-path.sh appgroup # Browse app groups
#
# Description:
#   Interactively browse iOS simulator containers. Select a simulator,
#   then pick an app or app group to view its sandbox path in Finder.
#
# Examples:
#   $ ./ios-sandbox-path.sh
#   Available Simulators:
#   1. iPhone 15 Pro
#   2. iPad Air
#   Pick a simulator (1-2): 1
#   Selected: iPhone 15 Pro
#
#   Installed Apps:
#   1. com.example.myapp
#   2. com.company.anotherapp
#   Pick an app (1-2): 1
#   Selected: com.example.myapp
#   Full Path:
#   /Users/.../Library/Developer/CoreSimulator/Devices/.../data/Containers/Data/Application/...
#   Done
#
#   $ ./ios-sandbox-path.sh appgroup
#   Available Simulators:
#   1. iPhone 15 Pro
#   Pick a simulator (1-1): 1
#   Selected: iPhone 15 Pro
#
#   App Groups:
#   1. group.com.example.shared
#   2. group.com.company.data
#   Pick an app group (1-2): 1
#   Selected: group.com.example.shared
#   Full Path:
#   /Users/.../Library/Developer/CoreSimulator/Devices/.../data/Containers/Shared/AppGroup/...
#   Done
#

set -euo pipefail

SIMULATORS_PATH="/Users/anandkumar/Library/Developer/CoreSimulator/Devices"
MODE="app"  # Default mode: "app" or "appgroup"

# Check for arguments
if [[ $# -gt 0 && "$1" == "appgroup" ]]; then
    MODE="appgroup"
fi

# Check if path exists
if [[ ! -d "$SIMULATORS_PATH" ]]; then
    echo "Simulators path not found: $SIMULATORS_PATH"
    exit 1
fi

# Get list of simulator UUIDs and names
simulators=()
declare -A simulator_map

for device_dir in "$SIMULATORS_PATH"/*; do
    if [[ -d "$device_dir" ]]; then
        uuid=$(basename "$device_dir")

        # Try to get simulator name from device.plist
        device_plist="$device_dir/device.plist"
        if [[ -f "$device_plist" ]]; then
            name=$(plutil -extract "name" raw "$device_plist" 2>/dev/null || echo "Unknown")
        else
            name="Unknown"
        fi

        simulators+=("$uuid")
        simulator_map[$uuid]=$name
    fi
done

if [[ ${#simulators[@]} -eq 0 ]]; then
    echo "Error: No simulators found"
    exit 1
fi

# Display simulators and ask user to pick
echo "Available Simulators:"
for i in {1..${#simulators[@]}}; do
    uuid=${simulators[$i]}
    name=${simulator_map[$uuid]}
    echo "$i. $name"
done

read -r "choice?Pick a simulator (1-${#simulators[@]}): "

# Validate choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#simulators[@]} )); then
    echo "Error: Invalid choice"
    exit 1
fi

selected_uuid=${simulators[$choice]}
echo "Selected: ${simulator_map[$selected_uuid]}"

# Set path based on mode
if [[ "$MODE" == "appgroup" ]]; then
    apps_path="$SIMULATORS_PATH/$selected_uuid/data/Containers/Shared/AppGroup"
else
    apps_path="$SIMULATORS_PATH/$selected_uuid/data/Containers/Data/Application"
fi

if [[ ! -d "$apps_path" ]]; then
    echo "Error: Path not found: $apps_path"
    exit 1
fi

# Collect apps/appgroups
apps=()
declare -A app_map  # Map app/appgroup to container path

if [[ "$MODE" == "appgroup" ]]; then
    # List app group directories
    for appgroup_dir in "$apps_path"/*; do
        if [[ -d "$appgroup_dir" ]]; then
            metadata_plist="$appgroup_dir/.com.apple.mobile_container_manager.metadata.plist"
            if [[ -f "$metadata_plist" ]]; then
                appgroup_id=$(plutil -extract "MCMMetadataIdentifier" raw "$metadata_plist" 2>/dev/null || echo "")
                # Skip Apple's own app groups and known system groups
                if [[ -n "$appgroup_id" && \
                      ! "$appgroup_id" =~ ^group\.com\.apple\. && \
                      ! "$appgroup_id" =~ ^com\.apple\. && \
                      ! "$appgroup_id" =~ \.groups\.com\.apple\.podcasts$ && \
                      "$appgroup_id" != "group.is.workflow.my.app" && \
                      "$appgroup_id" != "systemgroup.com.apple.accessorysetupkit" && \
                      "$appgroup_id" != "group.tvappservices.container" && \
                      "$appgroup_id" != "group.is.workflow.shortcuts" ]]; then
                    apps+=("$appgroup_id")
                    app_map[$appgroup_id]="$appgroup_dir"
                fi
            fi
        fi
    done
else
    # Collect app bundle IDs (excluding com.apple.*)
    for app_container in "$apps_path"/*; do
        if [[ -d "$app_container" ]]; then
            metadata_plist="$app_container/.com.apple.mobile_container_manager.metadata.plist"
            if [[ -f "$metadata_plist" ]]; then
                bundle_id=$(plutil -extract "MCMMetadataIdentifier" raw "$metadata_plist" 2>/dev/null || echo "")
                # Skip Apple's own apps
                if [[ -n "$bundle_id" && ! "$bundle_id" =~ ^com\.apple\. ]]; then
                    apps+=("$bundle_id")
                    app_map[$bundle_id]="$app_container"
                fi
            fi
        fi
    done
fi

if [[ ${#apps[@]} -eq 0 ]]; then
    if [[ "$MODE" == "appgroup" ]]; then
        echo "  No app groups found"
    else
        echo "  No third-party apps found"
    fi
    echo ""
    echo "Done"
    exit 0
fi

# If only one item, select it directly
if [[ ${#apps[@]} -eq 1 ]]; then
    selected_item=${apps[1]}
    selected_path=${app_map[$selected_item]}
else
    # Display items with indexes
    echo ""
    if [[ "$MODE" == "appgroup" ]]; then
        echo "App Groups:"
    else
        echo "Installed Apps:"
    fi
    for i in {1..${#apps[@]}}; do
        echo "$i. ${apps[$i]}"
    done

    if [[ "$MODE" == "appgroup" ]]; then
        read -r "choice?Pick an app group (1-${#apps[@]}): "
    else
        read -r "choice?Pick an app (1-${#apps[@]}): "
    fi

    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#apps[@]} )); then
        echo "Error: Invalid choice"
        exit 1
    fi

    selected_item=${apps[$choice]}
    selected_path=${app_map[$selected_item]}
fi

echo "Selected: $selected_item"
echo ""
echo "Full Path:"
echo "$selected_path"

# Open in Finder
open "$selected_path"

echo ""
echo "Done"
