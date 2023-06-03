

# Test adding and removing IP addresses from allowlist
echo -e "\n${NC}→ Tests adding IP values to allowlist"

  test_name="Valid IP should be recorded in the Redis allowlist"
    reset_redis
    
    cli_result=$(./wafris-cli.sh -A $valid_ip)

    if should_exist_in_sorted_set "allowed_ranges" "$valid_ip"; then      
      echo -e "${CHECK_MARK} ${NC} $test_name"
    else
      echo -e "${CROSS_MARK} ${NC} $test_name"
    fi

  test_name="Invalid IP should not be recorded in the Redis allowlist"
    reset_redis

    cli_result=$(./wafris-cli.sh -A $invalid_ip)

    if should_not_exist_in_sorted_set "-a" "allowed_ranges" "$invalid_ip"; then      
      echo -e "${CHECK_MARK} ${NC} $test_name"
    else
      echo -e "${CROSS_MARK} ${NC} $test_name"
    fi

  test_name="Invalid IP should return an error value"
    reset_redis

    cli_result=$(./wafris-cli.sh -A $invalid_ip)
    if [[ $? -eq 0 ]]; then
      echo -e "${CROSS_MARK} ${NC} $test_name"
    else
      if should_not_exist_in_sorted_set "-a" "allowed_ranges" "$invalid_ip"; then      
        echo -e "${CHECK_MARK} ${NC} $test_name"
      else
        echo -e "${CROSS_MARK} ${NC} $test_name"
      fi
    fi

  test_name="Non-IP should return an error value" 
    reset_redis

    cli_result=$(./wafris-cli.sh -A $non_ip)
    if [[ $? -eq 0 ]]; then
      echo -e "${CROSS_MARK} ${NC} $test_name"
    else
      if should_not_exist_in_sorted_set "-a" "allowed_ranges" "$non_ip"; then      
        echo -e "${CHECK_MARK} ${NC} $test_name"
      else
        echo -e "${CROSS_MARK} ${NC} $test_name"
      fi
    fi

  test_name="Nil should return an error value" 
    reset_redis

    cli_result=$(./wafris-cli.sh -A "")
    if [[ $? -eq 0 ]]; then
      echo -e "${CROSS_MARK} ${NC} $test_name"
    else
      echo -e "${CHECK_MARK} ${NC} $test_name"  
    fi
