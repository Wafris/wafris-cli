
# Test adding and removing IP addresses from blocklist
echo -e "\n${NC}→ Testing Wafris Blocking IP addresses"

  test_name="Unblocked IP address should not return a 403"
  reset_redis

  if [ "$(get_http_response_code $(test_url))" -eq 403 ]; then
    echo -e "${CROSS_MARK} ${NC} $test_name"
  else
    echo -e "${CHECK_MARK} ${NC} $test_name"
  fi

  test_name="Blocked IP address should return a 403"
  reset_redis

  ip_to_block="9.9.9.9"
  cli_result=$(./wafris-cli.sh -a $ip_to_block)

  if [ "$(get_http_response_code $(test_url) $ip_to_block)" -eq 403 ]; then
    echo -e "${CHECK_MARK} ${NC} $test_name"
  else
    echo -e "${CROSS_MARK} ${NC} $test_name"
  fi

  test_name="Blocked IP address above specified IP should not be blocked"
  reset_redis

  ip_to_test="9.9.9.10"
  
  if [ "$(get_http_response_code $(test_url) $ip_to_test)" -eq 200 ]; then
    echo -e "${CHECK_MARK} ${NC} $test_name"
  else
    echo -e "${CROSS_MARK} ${NC} $test_name"
  fi

  test_name="Blocked IP address below specified IP should not be blocked"
    reset_redis

  ip_to_block="9.9.9.8"

  if [ "$(get_http_response_code $(test_url) $ip_to_block)" -eq 200 ]; then
    echo -e "${CHECK_MARK} ${NC} $test_name"
  else
    echo -e "${CROSS_MARK} ${NC} $test_name"
  fi



