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

# HTTP Connection test
if can_connect $(test_url); then
  echo "Connection to: $(test_url) successful. Running tests."
else
  echo "Failed to connect to: $(test_url) check settings in config.env"
  echo "and that the HTTP with the Wafris client is running."
  exit 1
fi

# LOAD TEST SCRIPTS
SCRIPT_DIR="./client_tests"

for script in "$SCRIPT_DIR"/*.sh; do
  if [ -f "$script" ]; then
    source "$script"
  fi
done

