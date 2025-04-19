#!/bin/bash
set -e

FORMATTER=$1

if [ "$FORMATTER" = "prettier" ]; then
  npx prettier --write .
elif [ "$FORMATTER" = "black" ]; then
  black .
else
  echo "Unsupported formatter: $FORMATTER"
  exit 1
fi
