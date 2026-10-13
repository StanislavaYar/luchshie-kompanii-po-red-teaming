#!/usr/bin/env bash
# Mobile screenshot via 390px iframe harness (headless Chrome clamps window width to >=500).
# Usage: bash mshot.sh <path-on-server e.g. / or metodika-ocenki/> <height> <label>
p="$1"; h="$2"; label="$3"
printf '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:#888}iframe{border:0;width:390px;height:%spx;display:block}</style><iframe src="/%s"></iframe>' "$h" "${p#/}" > docs/_harness.html
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
DIR="temporary screenshots"; mkdir -p "$DIR"
n=$(ls "$DIR" | grep -v part | grep -c '^screenshot-' || true); n=$((n+1))
out="$DIR/screenshot-$n-$label.png"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=5000 \
  --window-size="500,$h" --screenshot="$(cygpath -w "$PWD/$out")" "http://localhost:4317/_harness.html" >/dev/null 2>&1
rm -f docs/_harness.html
powershell -NoProfile -ExecutionPolicy Bypass -File crop.ps1 "$(cygpath -w "$PWD/$out")" 1500 >/dev/null
echo "$out"
