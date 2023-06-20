echo -e "\n${NC}→ Testing Wafris Requests in Current Hour"

test_name="Single request should increment 60 redis keys"
reset_redis

response=$(get_http_response_code $(test_url))
if [ $(redis-cli keys "*hr-ct*" | wc -l) == "60" ]; then
	echo -e "${CHECK_MARK} ${NC} $test_name"
else
	echo -e "${CROSS_MARK} ${NC} $test_name"
fi
