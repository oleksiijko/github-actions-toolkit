#!/bin/bash
set -e

URL=$1
OUTPUT_FORMAT=$2

# Run Lighthouse to generate the performance report
lighthouse $URL --output $OUTPUT_FORMAT --output-path ./report.$OUTPUT_FORMAT

echo "Performance report saved as report.$OUTPUT_FORMAT"
