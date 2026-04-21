#!/usr/bin/env zsh

# ========================================================================
# Checks for the latest commit in 'Technical Notes' repo, identifies the most recently modified file in that commit, and opens it on GitHub.
# If blame argument is provided, opens the file in blame view instead of regular view.
#
# Example usage:
# ghopenlatest.sh          # Opens the latest modified file in regular view
# ghopenlatest.sh blame    # Opens the latest modified file in blame view
# ========================================================================

set -euo pipefail

cd /Users/anandkumar/Desktop/Technical\ Notes || exit 1
# cd /Users/anandkumar/Documents/Technical\ Notes || exit 1

# Determine the GitHub view type (blob or blame)
view_type="blob"
if [[ "${1-}" == "blame" ]]; then
  view_type="blame"
fi

# Get files changed in the latest commit
latest_file=""
latest_time=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  if [[ -f "$file" ]]; then
    mod_time=$(stat -f%m "$file" 2>/dev/null)
    if (( mod_time > latest_time )); then
      latest_time=$mod_time
      latest_file="$file"
    fi
  fi
done < <(git log -1 --name-only --pretty=format:"")

if [[ -z "$latest_file" ]]; then
  echo "No files found with valid modification dates"
  exit 1
fi

echo "$latest_file"

# URL encode the file path (replace spaces and special characters)
encoded_path=$(printf '%s' "$latest_file" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")

# Get the GitHub username and repo from git remote
remote_url=$(git config --get remote.origin.url)
if [[ $remote_url =~ 'github\.com[:/]([^/]+)/([^/]+)' ]]; then
  github_user="${match[1]}"
  github_repo="${match[2]}"
  # Remove .git suffix if present
  github_repo="${github_repo%.git}"

  # Construct and open the GitHub URL
  github_url="https://github.com/${github_user}/${github_repo}/${view_type}/master/${encoded_path}"
  echo "Opening: $github_url"
  open "$github_url"
else
  echo "Could not determine GitHub repository from remote URL: $remote_url"
  exit 1
fi
