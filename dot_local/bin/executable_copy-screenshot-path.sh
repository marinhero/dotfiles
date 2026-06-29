#!/bin/bash
# Watches ~/Screenshots: renames each new screenshot to clean ASCII
# (strips U+202F / U+00A0, collapses whitespace to underscores), then
# copies the resulting path to the clipboard.
# Triggered by a LaunchAgent on ~/Screenshots.

DIR="$HOME/Screenshots"

# Give screencapture a moment to finish writing/renaming the file.
sleep 0.3

latest=$(ls -dt "$DIR"/Screenshot*.png 2>/dev/null | head -1)
[ -n "$latest" ] || exit 0

base=$(basename "$latest")

# Clean name: narrow/no-break spaces -> space, then any whitespace run -> underscore.
clean=$(printf '%s' "$base" | perl -CSD -pe 's/[\x{202f}\x{00a0}]/ /g; s/\s+/_/g')

target="$DIR/$clean"

if [ "$base" != "$clean" ] && [ ! -e "$target" ]; then
    mv -n "$latest" "$target" && latest="$target"
fi

printf '%s' "$latest" | pbcopy
