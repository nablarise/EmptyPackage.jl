#!/bin/bash
# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Usage:
#   ./runtests.sh                  # Run tests with output to terminal
#   ./runtests.sh test/output.log  # Run tests with output to test/output.log
#
# Note: Output file paths are converted to absolute paths, so the file
#       will be created exactly where you specify relative to current directory.
#
# The script automatically restarts Julia when needed (e.g., world age errors).
# Press Ctrl+C to exit the test loop.
#
# Exit codes:
#   0: Normal exit via Ctrl+C
#   1: Parse error occurred - fix syntax and restart
#   Other: Unexpected error
#
# Status messages for AI agents:
#   "Successful exit of the revise-test loop!" - Loop ended normally
#   "Restart signal detected" - Auto-restarting due to world age error
#   "Tests failed with exit status X" - Unexpected failure

# Check for optional output file argument
if [ $# -gt 1 ]; then
  OUTPUT_FILE="$2"
elif [ $# -eq 1 ]; then
  OUTPUT_FILE="$1"
else
  OUTPUT_FILE=""
fi

# Convert relative path to absolute path for consistent behavior
if [ -n "$OUTPUT_FILE" ]; then
  # Get the directory and filename
  OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
  OUTPUT_NAME=$(basename "$OUTPUT_FILE")

  # Convert to absolute path
  if [ "$OUTPUT_DIR" = "." ]; then
    OUTPUT_FILE="$(pwd)/$OUTPUT_NAME"
  else
    OUTPUT_FILE="$(cd "$OUTPUT_DIR" 2>/dev/null && pwd)/$OUTPUT_NAME" || OUTPUT_FILE="$(pwd)/$OUTPUT_FILE"
  fi

  TEST_ARGS="[\"auto\", \"$OUTPUT_FILE\"]"
else
  TEST_ARGS="[\"auto\"]"
fi

# Run the Julia command and retry on failure
while true; do
  clear
  julia --project=@. -e "import Pkg; Pkg.test(; test_args = $TEST_ARGS);";

  # Check exit status and signal file
  EXIT_STATUS=$?

  echo $EXIT_STATUS
  
  if [ $EXIT_STATUS -eq 0 ] && [ ! -f "test/.restart_julia" ]; then
    echo "Successful exit of the revise-test loop!"
    break
  elif [ -f "test/.restart_julia" ]; then
    echo "Restart signal detected. Retrying in 3 seconds..."
    rm -f "test/.restart_julia"
    sleep 3
  else
    echo "Tests failed with exit status $EXIT_STATUS."
    echo "This case is not handled. Fix the error and try again."
    break
  fi
done
