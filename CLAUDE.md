# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of personal utility shell scripts for macOS, written primarily in zsh. Scripts handle various automation tasks including iOS development, personal finance tracking, file management, and git workflows.

## Technology Stack

- **Shell Language**: Primarily zsh (#!/usr/bin/env zsh or #!/bin/zsh)
- **Tools Used**: osascript (AppleScript), sed, awk, exiftool, security/PlistBuddy, git
- **Environment**: macOS only (uses macOS-specific paths, applications, APIs)

## Common Development Tasks

### Running Scripts
Scripts are self-contained and typically require directory or file paths as arguments:
```bash
/bin/zsh script-name.sh [arguments]
# or if executable:
./script-name.sh [arguments]
```

### Testing Scripts
Many scripts interact with external services or file systems. When modifying:
- Test with temporary files/directories when possible
- Use the trap mechanism for cleanup (see `verify-ipa-entitlements.sh` for pattern)
- Verify paths and file counts before operations (see `filter-expenses.sh` for validation pattern)

### Debugging
- Use `set -euo pipefail` in scripts that should fail on errors
- Common pattern: scripts use `echo` with emoji indicators (✅ for success, ❌ for failure)
- Add `print` statements (zsh style) when debugging output

## Script Categories and Key Patterns

### iOS/macOS Development
- `verify-ipa-entitlements.sh`: Extracts and validates iOS IPA entitlements. Uses security/PlistBuddy to inspect provisioning profiles. Creates temp directories with `mktemp` and cleans up with `trap`.

### Personal Finance Automation
- `extract-vanguard.sh`: Multi-step script that extracts portfolio HTML from Safari, processes with Python, cleans up temp files.
- `filter-expenses.sh`: Sophisticated workflow script that manages CSV files across Google Drive and Downloads, removes duplicate transactions, and opens PyCharm. Includes validation at each step.

### Git Workflow Helpers
- `thinkandpush.sh`: Force-pushes changes with smart commit creation/amendment based on commit age (default 14-day threshold). Can amend recent commits or create new ones. Set `THRESHOLD` env var to change the threshold.

### File Management Utilities
- `file-rename-*.sh`: Collection of zsh-specific file operations:
  - `file-rename-change-extension-case.sh`: Converts .MOV to .mov (uses zsh glob modifiers)
  - `file-rename-file-index.sh`: Sequentially renames files with numeric indices
  - `file-rename-print-coordinates.sh`: Extracts and prints GPS coordinates from image EXIF data using exiftool

### Misc Utilities
- `openmaps.sh`: Finds and opens files from a Google Drive Maps folder with case-insensitive search
- `estimate-page-count.sh`: Estimates printed pages for markdown files. Complex awk logic that accounts for code blocks, headings, lists, and tables.

## Important Implementation Notes

### zsh-Specific Patterns
- Array expansion: `"${ARRAY[@]}"` and `${#ARRAY[@]}`
- Glob modifiers: `${file:r}` (remove extension), `${file:e}` (extension only)
- Parameter expansion: `${variable%%pattern}` (remove suffix)
- Process substitution: `< <(command)` instead of piping
- Conditional expressions: `[[ ]]` with pattern matching and operators like `=~`, `==*`, `-f`, `-d`

### File Path Handling
- Many scripts use hardcoded absolute paths to Google Drive/user directories
- Paths often use special syntax like `-write2anand.kumar@gmail.com` in Google Drive paths
- Always quote variables in path operations: `"$dir"/$file`

### Integration Patterns
- Scripts often integrate multiple tools (shell + osascript + Python + external CLIs)
- Common pattern: stage work, require manual intervention, continue processing
- Error handling through file/line count validation before proceeding (see `filter-expenses.sh`)

### Git Operations
- `thinkandpush.sh` uses `git add *` followed by conditional commit/amend logic
- Force push pattern: `git push origin HEAD --force`
- Date handling: uses epoch timestamps for comparisons

## Known Issues and Quirks

- `verify-ipa-entitlements.sh` contains apparent syntax errors (spaces in entitlement keys, malformed variable expansions, grep syntax issues)
- Some scripts use hardcoded full paths that are specific to the author's machine
- `extract-vanguard.sh` relies on specific Python project structure that may not be available

## Testing and Validation

Many scripts include defensive checks:
- Count files before/after operations (see `filter-expenses.sh` CSV validation)
- Check for required files before processing (see `verify-ipa-entitlements.sh`)
- Use informative error messages with exit codes
- Backup files before modifying them (see `filter-expenses.sh` backup pattern)
