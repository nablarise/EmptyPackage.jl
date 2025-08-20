#!/bin/bash

# Check for optional output file argument
if [ $# -gt 1 ]; then
  OUTPUT_FILE="$2"
  TEST_ARGS="[\"auto\", \"$OUTPUT_FILE\"]"
elif [ $# -eq 1 ]; then
  OUTPUT_FILE="$1"
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
