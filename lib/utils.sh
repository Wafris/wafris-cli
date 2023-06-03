#!/bin/bash

# This file can contain various utility functions that can be sourced in other scripts
# For example:
function is_valid_ip {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi

  return $stat
}

function ip_to_int {
    local ip=$1
    IFS='.' read -ra ADDR <<< "$ip"
    echo "$(( (${ADDR[0]} << 24) + (${ADDR[1]} << 16) + (${ADDR[2]} << 8) + ${ADDR[3]} ))"
}

function reset_redis {
    redis-cli FLUSHDB &>/dev/null
}

# Function to execute redis-cli command and return the result
function execute_redis_command() {
  local commands="$1"
  result=$(redis-cli $commands)
  echo "$result"
}


# REDIS CLI CHECKS
## Check if redis-cli is installed
function check_redis_cli {
  if ! command -v redis-cli &> /dev/null
  then
      echo -e "${CROSS_MARK} Redis CLI could not be found. Please install it and try again."
      return 1
  else
      echo -e "${CHECK_MARK} Redis CLI is installed."
      return 0
  fi
}

## Check redis-cli version
function check_redis_cli_version {
  local REDIS_CLI_VERSION=$(redis-cli --version | awk '{print $2}' | cut -d'=' -f2)

  if (( $(echo "$REDIS_CLI_VERSION" | cut -d'.' -f1) >= MIN_REDIS_CLIENT_VERSION )); then
    echo -e "${CHECK_MARK} Redis CLI version is $REDIS_CLI_VERSION, which meets the minimum requirement of $MIN_REDIS_CLIENT_VERSION or higher."
    return 0
  else   
    echo "Redis CLI version is $REDIS_CLI_VERSION, which does not meet the minimum requirement of $MIN_REDIS_CLIENT_VERSION or higher."
    return 1
  fi
}


# REDIS SERVER CHECKS
## Check connection to Redis server
function check_redis_server_connection {
  if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping &>/dev/null; then
    echo -e "${CHECK_MARK} Successfully connected to Redis server at $REDIS_HOST:$REDIS_PORT."
    return 0
  else
    echo -e "${CROSS_MARK} Failed to connect to Redis server at $REDIS_HOST:$REDIS_PORT - check settings in config.env"
    return 1
  fi
}

## Check redis-server version
function check_redis_server_version {

  local REDIS_SERVER_VERSION=$(redis-server --version | awk '{print $3}' | cut -d'=' -f2)

  if (( $(echo "$REDIS_SERVER_VERSION" | cut -d'.' -f1) >= MIN_REDIS_SERVER_VERSION )); then
    echo -e "${CHECK_MARK} Redis server version is $REDIS_SERVER_VERSION, which meets the minimum requirement of $MIN_REDIS_SERVER_VERSION or higher."
    return 0
  else
    echo -e "${CROSS_MARK} Redis server version is $REDIS_SERVER_VERSION, which does not meet the minimum requirement of $MIN_REDIS_SERVER_VERSION or higher."
    return 1
  fi
}


# TESTING FUNCTIONS
# Function to check if the value exists in the Redis sorted set
should_exist_in_sorted_set() {
  local sorted_set_name=$1
  local value=$2

  # Check if the IP address does not exist in the list
  local result=$(execute_redis_command "ZRANK $sorted_set_name $value")

  if [[ -n $result ]]; then
    return 0
  else    
    echo " - Output from Redis: '$result'"
    return 1
  fi  
}


# Function to check if a value does not exist in the Redis sorted set
should_not_exist_in_sorted_set() {
  local action=$1
  local sorted_set_name=$2
  local value=$3

  # Execute the action
  local cli_result=$(./wafris-cli.sh $action $value)

  # Check if the IP address does not exist in the list
  local result=$(execute_redis_command "ZRANK $sorted_set_name $value")

  if [[ -z $result ]]; then
    return 0
  else    
    echo "  - Output from Redis: '$result'"
    return 1
  fi
}


# CURL UTLITITY FUNCTIONS

## Check if HTTP servers is up for testing
function can_connect() {
  local url=$1
  if curl --output /dev/null --silent --head --fail "$url"; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}


## Takes a URL and an IP address and returns the HTTP response code
function get_http_response_code() {
  local url=$1
  local header=$2

  # No IP address provided
  if [[ -z $header ]]; then
    response_code=$(curl -s -o /dev/null -I -w "%{http_code}" $url)

  # Supplied IP address
  else
    response_code=$(curl -s -o /dev/null -I -H "X-Forwarded-For: $ip" -w "%{http_code}" $url)
  fi
  echo $response_code
}

function test_url() {
  echo "${HTTP_PROTOCOL}://${HTTP_HOST}:${HTTP_PORT}"
}