local version = "v0.8:"
local wafris_prefix = "w:" .. version

local function get_time_bucket_from_timestamp(unix_time_milliseconds, minutes_flag)
  local function calculate_years_number_of_days(yr)
    return (yr % 4 == 0 and (yr % 100 ~= 0 or yr % 400 == 0)) and 366 or 365
  end

  local function get_year_and_day_number(year, days)
    while days >= calculate_years_number_of_days(year) do
      days = days - calculate_years_number_of_days(year)
      year = year + 1
    end
    return year, days
  end

  local function get_month_and_month_day(days, year)
    local days_in_each_month = {
      31,
      (calculate_years_number_of_days(year) == 366 and 29 or 28),
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    }

    for month = 1, #days_in_each_month do
      if days - days_in_each_month[month] <= 0 then
        return month, days
      end
      days = days - days_in_each_month[month]
    end
  end

  local unix_time = unix_time_milliseconds / 1000
  local year = 1970
  local days = math.ceil(unix_time / 86400)
  local month = nil

  year, days = get_year_and_day_number(year, days)
  month, days = get_month_and_month_day(days, year)
  local hours = math.floor(unix_time / 3600 % 24)
  -- local minutes, seconds = math.floor(unix_time / 60 % 60), math.floor(unix_time % 60)
  -- hours = hours > 12 and hours - 12 or hours == 0 and 12 or hours
  if minutes_flag == false then
    return string.format("%04d%02d%02d%02d", year, month, days, hours)
  elseif minutes_flag == true then
    local minutes = math.floor(unix_time / 60 % 60)
    return string.format("%04d%02d%02d%02d%02d", year, month, days, hours, minutes)
  end
end

-- For: Relationship of IP to time of Request (Stream)
local function get_request_id(timestamp, ip, max_requests)
  timestamp = timestamp or "*"
  local request_id = redis.call("XADD", "ip-requests-stream", "MAXLEN", "~", max_requests, timestamp, "ip", ip)
  return request_id
end

local function add_to_graph_timebucket(timebucket, request_id)
  local key = wafris_prefix .. "gr-ct:" .. timebucket
  redis.call("PFADD", key, request_id)
  -- Expire the key after 25 hours if it has no expiry
  redis.call("EXPIRE", key, 90000)
end

-- For: Leaderboard of IPs with Request count as score
local function increment_timebucket_for(type, timebucket, property)
  local key = wafris_prefix .. type .. "lb:" .. timebucket
  redis.call("ZINCRBY", key, 1, property)
  -- Expire the key after 25 hours if it has no expiry
  redis.call("EXPIRE", key, 90000)
end

local function increment_partial_hourly_request_counters(unix_time_milliseconds)
  for i = 1, 60 do
    local timebucket_in_milliseconds = unix_time_milliseconds + 60000 * (i - 1)
    local timebucket = get_time_bucket_from_timestamp(timebucket_in_milliseconds, true)
    local key = wafris_prefix .. "hr-ct:" .. timebucket
    redis.call("INCR", key)
    -- Expire the key after 121 minutes if it has no expiry
    redis.call("EXPIRE", key, 7260)
  end
end

-- Configuration
local max_requests = 1000000
local max_requests_per_ip = 100000

local client_ip = ARGV[1]
local client_ip_to_decimal = ARGV[2]
local unix_time_milliseconds = ARGV[3]
local unix_time = ARGV[3] / 1000
local user_agent = ARGV[4]
local request_path = ARGV[5]
local host = ARGV[6]
local method = ARGV[7]

-- Initialize local variables
-- local request_id = get_request_id(nil, client_ip, max_requests)
local current_timebucket = get_time_bucket_from_timestamp(unix_time_milliseconds, false)

-- CARD DATA COLLECTION
increment_partial_hourly_request_counters(unix_time_milliseconds)

-- GRAPH DATA COLLECTION
-- add_to_graph_timebucket(current_timebucket, request_id)

-- LEADERBOARD DATA COLLECTION
increment_timebucket_for("ip:", current_timebucket, client_ip)
increment_timebucket_for("ua:", current_timebucket, user_agent)
increment_timebucket_for("path:", current_timebucket, request_path)
increment_timebucket_for("host:", current_timebucket, host)


-- NEW RELATIONAL STRUCTURE
  -- using timestamp as id but should be * in production  
  local stream_id = unix_time_milliseconds .. "-0"

-- IP Address Request Property
local ip_id = redis.call("HGET", "ip-value-to-id", client_ip)

if ip_id == false then
  ip_id = redis.call("INCR", "ip-id-counter")
  redis.call("HSET", "ip-value-to-id", client_ip, ip_id)
  redis.call("HSET", "ip-id-to-value", ip_id, client_ip)
end

-- User Agent Request Property
local ua_id = redis.call("HGET", "ua-value-to-id", user_agent)

if ua_id == false then
  ua_id = redis.call("INCR", "ua-id-counter")
  redis.call("HSET", "ua-value-to-id", user_agent, ua_id)
  redis.call("HSET", "ua-id-to-value", ua_id, user_agent)
end

-- Path Request Property
local path_id = redis.call("HGET", "path-value-to-id", request_path)

if path_id == false then
  path_id = redis.call("INCR", "path-id-counter")
  redis.call("HSET", "path-value-to-id", request_path, path_id)
  redis.call("HSET", "path-id-to-value", path_id, request_path)
end

-- Host Request Property
local host_id = redis.call("HGET", "host-value-to-id", host)

if host_id == false then
  host_id = redis.call("INCR", "host-id-counter")
  redis.call("HSET", "host-value-to-id", host, host_id)
  redis.call("HSET", "host-id-to-value", host_id, host)
end

-- Method Request Property
local method_id = redis.call("HGET", "method-value-to-id", method)

if method_id == false then
  method_id = redis.call("INCR", "method-id-counter")
  redis.call("HSET", "method-value-to-id", method, method_id)
  redis.call("HSET", "method-id-to-value", method_id, method)
end



-- Adding Request 
  local request_id = redis.call("XADD", "requestsStream", "MAXLEN", "~", max_requests, stream_id, "ip_id", ip_id, "ua_id", ua_id, "path_id", path_id, "host_id", host_id, "method_id", method_id)
 
-- Adding to Property Streams
  local ip_to_request_stream = "ip-to-request-stream:" .. tostring(ip_id)
  local ip_request_id = redis.call("XADD", ip_to_request_stream, "MAXLEN", "~", max_requests, "*", "r_id", stream_id)
  
  local ua_to_request_stream = "ua-to-request-stream:" .. tostring(ua_id)
  local ua_request_id = redis.call("XADD", ua_to_request_stream, "MAXLEN", "~", max_requests, "*", "r_id", stream_id)
  
  local path_to_request_stream = "path-to-request-stream:" .. tostring(path_id)
  local path_request_id = redis.call("XADD", path_to_request_stream, "MAXLEN", "~", max_requests, "*", "r_id", stream_id)
  
  local host_to_request_stream = "host-to-request-stream:" .. tostring(host_id)
  local host_request_id = redis.call("XADD", host_to_request_stream, "MAXLEN", "~", max_requests, "*", "r_id", stream_id)
  
  local method_to_request_stream = "method-to-request-stream:" .. tostring(method_id)
  local method_request_id = redis.call("XADD", method_to_request_stream, "MAXLEN", "~", max_requests, "*", "r_id", stream_id)
  



-- Adding to Property Existence Sets
  redis.call("SADD", "ip-requests-set", client_ip)


return ip_request_id









