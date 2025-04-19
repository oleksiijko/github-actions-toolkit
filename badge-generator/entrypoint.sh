#!/bin/bash
set -e

LABEL="$INPUT_LABEL"
MESSAGE="$INPUT_MESSAGE"
COLOR="${INPUT_COLOR:-gray}"
FILENAME="${INPUT_FILENAME:-badge.svg}"

echo "🏷️ Generating badge: [$LABEL][$MESSAGE] with color $COLOR"

SVG="<?xml version=\"1.0\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"150\" height=\"20\">
  <rect width=\"75\" height=\"20\" fill=\"#555\"/>
  <rect x=\"75\" width=\"75\" height=\"20\" fill=\"$COLOR\"/>
  <text x=\"37.5\" y=\"14\" fill=\"#fff\" font-family=\"Verdana\" font-size=\"11\" text-anchor=\"middle\">$LABEL</text>
  <text x=\"112.5\" y=\"14\" fill=\"#fff\" font-family=\"Verdana\" font-size=\"11\" text-anchor=\"middle\">$MESSAGE</text>
</svg>"

echo "$SVG" > "$FILENAME"

echo "✅ Badge saved as $FILENAME"
