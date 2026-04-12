#!/usr/bin/env zsh

# ========================================================================
# Checks if the previous commit is older than a defined threshold (14 days by default).
#   If its older, then creates a new commit with the provided commit note (or "WIP" if none provided).
#   Else, amends the latest commit by appending the provided commit note (if not already present).
# Force pushes the changes to remote repository.
#
# Example usage:
# thinkandpush.sh <optional-commit-note>
# ========================================================================

set -euo pipefail

cd /Users/anandkumar/Documents/Technical\ Notes || exit 1

# Save all arguments as commit_note if provided, else default to "WIP"
if (( $# > 0 )); then
  commit_note="$*"
else
  commit_note=""
fi

# Define threshold
THRESHOLD=${THRESHOLD:-$((14 * 24 * 60 * 60))}  # 14 days in seconds
# THRESHOLD=${THRESHOLD:-$((10))}  # 10 seconds (for testing)

# Get latest commit's author date (epoch + ISO for display)
authordate_epoch=$(git show -s --format=%at HEAD)
authordate_iso=$(git show -s --format=%aI HEAD)

now_epoch=$(date +%s)

# Check if the latest commit is older than the threshold
seconds_elapsed_since_authordate=$(( now_epoch - authordate_epoch ))
approx_days_elapsed_since_authordate=$(( seconds_elapsed_since_authordate / 86400 ))

if (( seconds_elapsed_since_authordate > THRESHOLD )); then
  is_old_commit=1
else
  is_old_commit=0
fi

print "Latest commit author date : ${authordate_iso}"
print "Days since author date    : ${approx_days_elapsed_since_authordate}"
print "Threshold                 : $(( THRESHOLD / (24 * 60 * 60) )) days"
print "is_old_commit (1 ~ Yes)   : ${is_old_commit}"

# Stage all changes, commit, and force push
git add * ; 

if (( is_old_commit == 1 )); then
  new_subject="${commit_note:-WIP}" # If commit_note is empty, use "WIP" as new_subject
  git commit -m "${new_subject}"
else  
  latest_subject=$(git log -1 --pretty=%s HEAD)

  # If the commit_note is empty or if latest commit message already contains the commit_note, do not append it again
  if [[ -z "$commit_note" || "$latest_subject" == *"$commit_note"* ]]; then
    git commit --amend --no-edit
  else
    new_subject="${latest_subject}, ${commit_note}"
    git commit --amend -m "${new_subject}"
  fi
fi

git push origin HEAD --force