#!/usr/bin/env bash
# Usage: bash shot.sh <url> <width> <height> <label>
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
DIR="temporary screenshots"; mkdir -p "$DIR"
n=$(ls "$DIR" | grep -v part | grep -c '^screenshot-' || true); n=$((n+1))
out="$DIR/screenshot-$n-$4.png"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=4000 \
  --window-size="$2,$3" --screenshot="$(cygpath -w "$PWD/$out")" "$1" >/dev/null 2>&1
echo "$out"
