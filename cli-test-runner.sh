#!/bin/bash

# Load the configuration variables
source config.env
# Load utility functions
source lib/utils.sh

# Check if TEST_MODE is set to true
if [[ "$TEST_MODE" == "false" ]]; then
  echo "TEST_MODE is set to false. Set to 'true' in config.env to run tests"
  exit 1
fi

# IP variations
valid_ip="1.1.1.1"
invalid_ip="999.999.999.999"
non_ip="abc"

# LOAD TEST SCRIPTS
SCRIPT_DIR="./cli_tests"

for script in "$SCRIPT_DIR"/*.sh; do
  if [ -f "$script" ]; then
    source "$script"
  fi
done

