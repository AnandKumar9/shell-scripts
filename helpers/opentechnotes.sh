#!/usr/bin/env zsh

# Path to the main Technical Notes folder
MAIN_NOTES_DIR="/Users/anandkumar/Documents/Technical Notes"

# Function to open folder with Typora
open_with_typora() {
    local folder="$1"
    open -a "Typora.app" "$folder"
}

# Main logic
if [[ $# -eq 0 ]]; then
    # No arguments: open main Technical Notes folder
    open_with_typora "$MAIN_NOTES_DIR"
else
    # Get the first argument (ignore rest if more than one)
    local search_term="$1"

    # Search for folders with the given name
    local matches=()
    while IFS= read -r folder; do
        matches+=("$folder")
    done < <(find "$MAIN_NOTES_DIR" -type d -name "*$search_term*" 2>/dev/null)

    if [[ ${#matches[@]} -eq 1 ]]; then
        # Exactly one match: open it
        open_with_typora "${matches[1]}"
    else
        # Zero or more than one match: open main folder
        open_with_typora "$MAIN_NOTES_DIR"
    fi
fi
