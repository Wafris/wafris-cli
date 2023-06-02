#!/bin/bash

echo "WAFRIS CLI"

# Load the configuration variables
source config.env

# Load utility functions
source lib/utils.sh

# Function to display help
display_help() {
  echo "Usage: ./wafris-cli.sh [OPTIONS]"
  echo
  echo "Options:"
  echo "-a  Add IP address to blocklist"
  echo "-r  Remove IP address from blocklist"
  echo "-A  Add IP address to allowlist"
  echo "-R  Remove IP address from allowlist"
  echo "-g  Get top requesting IPs"
  echo "-b  Get top blocked IPs"
  echo "-h  Display this help menu"
  echo
  echo "Example:"
  echo "    ./wafris-cli.sh -a 1.1.1.1"
}

# Exeute redis-cli commands
execute_redis_command() {
  local commands="$1"

  # Execute the redis-cli commands
  result=$(redis-cli $commands)

  # Check if the commands were successful
  if [[ $? -eq 0 ]]; then        
    return 0  # Return success
  else
    return 1  # Return failure
  fi
}

# Function to add IP address to blocklist
add_to_blocklist() {
  local ip_address=$1
  if is_valid_ip "$ip_address"; then
    local ip_integer=$(ip_to_int "$ip_address")
    
    if execute_redis_command "ZADD blocked_ranges $ip_integer $ip_address"; then
        echo "$ip_address added to blocklist"
        exit 0
    else
        echo "Failed to add $ip_address blocklist"
        exit 1
    fi

  else
    echo "Invalid IP address: $ip_address"
    exit 1
  fi
}

# Function to remove IP address from blocklist
remove_from_blocklist() {
  local ip_address=$1
  if is_valid_ip "$ip_address"; then
    local ip_integer=$(ip_to_int "$ip_address")
    
    if execute_redis_command "ZREM blocked_ranges $ip_address"; then
        echo "$ip_address removed from blocklist"
        exit 0
    else
        echo "Failed to remove $ip_address from blocklist"
        exit 1
    fi

  else
    echo "Invalid IP address: $ip_address"
    exit 1
  fi
}

# Function to add IP address to allowlist
# Function to add IP address to allowlist
add_to_allowlist() {
    local ip_address=$1
    if is_valid_ip "$ip_address"; then
        local ip_integer=$(ip_to_int "$ip_address")
        
        if execute_redis_command "ZADD allowed_ranges $ip_integer $ip_address"; then
                echo "$ip_address added to allowlist"
                exit 0
        else
                echo "Failed to add $ip_address to allowlist"
                exit 1
        fi

    else
        echo "Invalid IP address: $ip_address"
        exit 1
    fi
}

# Function to remove IP address from allowlist
remove_from_allowlist() {
  local ip_address=$1
  if is_valid_ip "$ip_address"; then
    local ip_integer=$(ip_to_int "$ip_address")
    
    if execute_redis_command "ZREM blocked_ranges $ip_address"; then
        echo "$ip_address removed from blocklist"
        exit 0
    else
        echo "Failed to remove $ip_address from blocklist"
        exit 1
    fi

  else
    echo "Invalid IP address: $ip_address"
    exit 1
  fi
}

# Function to get top requests
get_top_requests() {
  echo "Action: Get top requests"
  # Add your code here to get the top requests
}

# Function to get top blocks
get_top_blocks() {
  echo "Action: Get top blocks"
  # Add your code here to get the top blocks
}

# Parse options
while getopts ":a:r:A:R:gbh" opt; do
  case ${opt} in
    a ) 
      # Add to blocklist
      add_to_blocklist "$OPTARG"
      ;;
    r ) 
      # Remove from blocklist
      remove_from_blocklist "$OPTARG"
      ;;
    A ) 
      # Add to allowlist
      add_to_allowlist "$OPTARG"
      ;;
    R ) 
      # Remove from allowlist
      remove_from_allowlist "$OPTARG"
      ;;
    g ) 
      # Get top requests
      get_top_requests
      ;;
    b ) 
      # Get top blocks
      get_top_blocks
      ;;
    h ) 
      # Display help
      display_help
      exit
      ;;
    \? ) 
      echo "Invalid Option: -$OPTARG" 1>&2
      display_help
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      display_help
      exit 1
      ;;
  esac
done

# If no options were provided, display help
if [[ $OPTIND -eq 1 ]]; then
  display_help
fi
