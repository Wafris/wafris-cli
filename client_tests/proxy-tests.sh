# Test adding and removing IP addresses from blocklist
echo -e "\n${NC}→ Testing Wafris Returning correct client IP address with a proxy"

test_name="Requesting with the default localhost (127.0.0.1) range"
reset_redis

ips_to_test="3.4.5.6,127.0.0.1"
response=$(get_http_response_code $(test_url) $ips_to_test)
if [ $(redis-cli zrange $(redis-cli keys "*ip-leader*") 0 0) == "3.4.5.6" ]; then
	echo -e "${CHECK_MARK} ${NC} $test_name"
else
	echo -e "${CROSS_MARK} ${NC} $test_name"
fi

test_name="Requesting with user defined proxy (9.9.9.20)"
reset_redis

ips_to_test="3.4.5.6,9.9.9.20"
response=$(get_http_response_code $(test_url) $ips_to_test)
if [ $(redis-cli zrange $(redis-cli keys "*ip-leader*") 0 0) == "3.4.5.6" ]; then
	echo -e "${CHECK_MARK} ${NC} $test_name"
else
	echo -e "${CROSS_MARK} ${NC} $test_name"
	echo -e "    Make sure you have your proxy set via MY_PROXIES=9.9.9.20 with your app server."
fi
