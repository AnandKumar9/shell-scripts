#!/bin/zsh

osascript -e 'tell application "Typora" to quit' 2>/dev/null

APP="/Applications/Typora.app"
ICON="/Users/anandkumar/Documents/Icons/Typora-modified.icns"

fileicon set "$APP" "$ICON"

sudo rm -rf /Library/Caches/com.apple.iconservices.store
rm -rf ~/Library/Caches/com.apple.iconservices.store

rm -rf ~/Library/Caches/com.apple.iconservices*(N)
rm -rf ~/Library/Caches/com.apple.dock.iconcache*(N)

# /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    # -kill -r -domain local -domain system -domain user

killall Finder 2>/dev/null
killall Dock 2>/dev/null

echo "Done"