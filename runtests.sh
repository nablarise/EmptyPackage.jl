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

OUTPUT_FILE=""
if [ $# -ge 1 ]; then
    # Convert to absolute path to avoid ambiguity
    OUTPUT_FILE=$(realpath "$1" 2>/dev/null || echo "$(pwd)/$1")

    # clear file content at startup
    > "$OUTPUT_FILE"

    TEST_ARGS="[\"auto\", \"$OUTPUT_FILE\", \"jsonl\"]"
    echo "Logs redirected to: $OUTPUT_FILE"
else
    # Interactive mode: use temp file + tail + plain text format
    TEST_ARGS="[\"auto\", \"\", \"plain\"]"

    # Determine temp file path (must match Julia's default)
    TEMP_DIR="${TMPDIR:-/tmp}"
    TEMP_OUTPUT_FILE="$TEMP_DIR/julia_revise_test_output.log"

    # Clear temp file
    > "$TEMP_OUTPUT_FILE"

    echo "Interactive mode: Watching for changes..."
    echo "Press Ctrl+C to stop."
fi

# Special exit code to request a restart (World Age Error)
EXIT_CODE_RESTART=100

while true; do
    # Run Julia.
    # Note: We let Julia handle the output redirection logic internally if needed.
    julia --project=@. -e "import Pkg; Pkg.test(; test_args = $TEST_ARGS);"
    
    EXIT_STATUS=$?

    # Control Logic
    if [ $EXIT_STATUS -eq $EXIT_CODE_RESTART ]; then
        echo "[BASH] Restart signal received (World Age Error). Restarting in 1s..."
        sleep 1
        continue # Loop again
    elif [ $EXIT_STATUS -eq 0 ]; then
        echo "[BASH] Clean exit."
        exit 0
    else
        echo "[BASH] Error (Exit Code: $EXIT_STATUS). Check logs."
        exit $EXIT_STATUS
    fi
done
