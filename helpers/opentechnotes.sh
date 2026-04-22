#!/usr/bin/env zsh

# Usage:
#   opentechnotes
#     Opens MAIN_NOTES_DIR in Typora.
#   opentechnotes <search-term>
#     Opens the matching folder in Typora when there is exactly one match.
#     If there are zero or multiple matches, opens MAIN_NOTES_DIR in Typora.
#   opentechnotes <search-term> -finder
#     Opens the matching folder in Finder when there is exactly one match.
#     If there are zero or multiple matches, opens MAIN_NOTES_DIR in Finder.
#   opentechnotes <search-term> -png
#     Searches for exactly one matching folder under MAIN_NOTES_DIR.git
#     Counts PNG files recursively under that folder, excluding image-*.png files.
#     If fewer than 5 files are found, opens them one by one in Preview.app.
# The script always prints the path it is about to open.
#
# Examples:
#   opentechnotes : Open the 'Technical Notes' folder in Typora.
#   opentechnotes IDEs : Search for a folder matching "IDEs", open it in Typora if exactly one match is found.
#   opentechnotes IDEs -finder : Search for a folder matching "IDEs", open it in Finder if exactly one match is found.
#   opentechnotes IDEs -png : Search for a folder matching "IDEs", if exactly one match is found, search under it for PNG files that are not image-*.png and open them one by one in Preview if fewer than 5 are found.

# Path to the main Technical Notes folder
# MAIN_NOTES_DIR="/Users/anandkumar/Documents/Technical Notes"
MAIN_NOTES_DIR="/Users/anandkumar/Desktop/Technical Notes"

# Function to open folder with Typora
open_with_typora() {
    local folder="$1"
    open -a "Typora.app" "$folder"
}

# Function to open folder in Finder
open_in_finder() {
    local folder="$1"
    open -R "$folder"
}

open_png_files() {
    local search_root="$1"
    local png_files=()
    local file

    while IFS= read -r file; do
        png_files+=("$file")
    done < <(find "$search_root" -type f -iname "*.png" ! -iname "image-*.png" 2>/dev/null)

    printf 'Matching png files: %d\n' "${#png_files[@]}"

    if [[ ${#png_files[@]} -gt 0 && ${#png_files[@]} -lt 5 ]]; then
        for file in "${png_files[@]}"; do
            open -a "Preview.app" "$file"
        done
    fi
}

# Main logic
if [[ $# -eq 0 ]]; then
    # No arguments: open main Technical Notes folder
    open_with_typora "$MAIN_NOTES_DIR"
else
    search_term="$1"
    use_finder=false
    use_png=false
    if [[ "$2" == "-finder" ]]; then
        use_finder=true
    elif [[ "$2" == "-png" ]]; then
        use_png=true
    fi

    open_target() {
        local folder="$1"
        printf '%s\n' "$folder"
        if [[ "$use_finder" == true ]]; then
            open_in_finder "$folder"
        else
            open_with_typora "$folder"
        fi
    }

    # Search for folders containing the given name, ignoring case
    matches=()
    while IFS= read -r folder; do
        matches+=("$folder")
    done < <(find "$MAIN_NOTES_DIR" -type d -iname "*$search_term*" 2>/dev/null)

    if [[ ${#matches[@]} -eq 1 ]]; then
        if [[ "$use_png" == true ]]; then
            # Exactly one match: search it for PNG files that are not image-*.png
            open_png_files "${matches[1]}"
        else
            # Exactly one match: open it
            open_target "${matches[1]}"
        fi
    else
        if [[ "$use_png" == true ]]; then
            printf 'Expected exactly one matching folder for "%s"; found %d. Skipping PNG search.\n' "$search_term" "${#matches[@]}"
        else
            if [[ ${#matches[@]} -gt 1 ]]; then
                printf 'Multiple matching folders for "%s":\n' "$search_term"
                printf '%s\n' "${matches[@]}"
            fi
            # Zero or more than one match: open main folder
            open_target "$MAIN_NOTES_DIR"
        fi
    fi
fi
