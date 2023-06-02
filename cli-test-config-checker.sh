#!/bin/bash

source 'config.env'
source 'lib/utils.sh'

ERRORS_FOUND=false

# REDIS CLI CHECKS
echo -e "\n${NC}→ Checking Redis CLI"

## Check if redis-cli is installed
if ! check_redis_cli; then
  ERRORS_FOUND=true
fi

check_redis_cli_version
if [ $? -eq 1 ]; then
  ERRORS_FOUND=true
fi

# REDIS SERVER CHECKS
echo -e "\n${NC}→ Checking Redis Server"

check_redis_server_connection
if [ $? -eq 1 ]; then
  ERRORS_FOUND=true
fi

check_redis_server_version
if [ $? -eq 1 ]; then
  ERRORS_FOUND=true
fi


# SUMMARY
if [ "$ERRORS_FOUND" = true ]; then
  echo -e "\n$ ${CROSS_MARK} ${RED}Errors were found.${NC}"
else
  echo -e "\n🎉 ${GREEN}All checks passed. You're good to go!${NC}"
fi