

-- Configuration
local version = "v0.9-"
local wafris_prefix = "w-" .. version

local max_requests = 10000

local client_ip = ARGV[1]
local unix_time_milliseconds = ARGV[2]
local unix_time = ARGV[2] / 1000
local user_agent = ARGV[3]
local path = ARGV[4]
local parameters = ARGV[5]
local host = ARGV[6]
local method = ARGV[7]

 -- not stored, but used for block filtering
local headers = ARGV[7]
local post_body = ARGV[8]
local use_timestamps_as_request_ids = true

-- Sets timebuckets
-- unix_time_milliseconds: unix time in milliseconds
-- minutes_flag: boolean, if true, returns timebucket with minutes, if false, returns timebucket without minutes
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

-- Leaderboards: Listing of properties and how many requests in a timebucket
local function increment_leaderboard_for(property_abbreviation, timebucket, property_id)
  local key = property_abbreviation .. "L" .. timebucket
  redis.call("ZINCRBY", key, 1, property_id)
  -- Expire the key after 25 hours if it has no expiry
  redis.call("EXPIRE", key, 90000)
end

-- Request Property Loading and Mapping
local function set_property_value_id_lookups(property_abbreviation, property_value)

  -- Checks if the key already exists in the property hash
  -- the name ("ip") has a value (ex: "1.2.3.4") to the property id (ex: 1)
  local property_id = redis.call("HGET", property_abbreviation .. "-v-id", property_value)

  if property_id == false 
  then
    property_id = redis.call("INCR", property_abbreviation .. "-id-counter")
    redis.call("HSET", property_abbreviation .. "-v-id", property_value, property_id)
    redis.call("HSET", property_abbreviation .. "-id-v", property_id, property_value)
  end

  return property_id
end

-- Creates a hash for each unique property and adds request ids as entries
local function set_property_to_requests(property_abbreviation, property_id, request_id, blocked)
  redis.call("HSET", property_abbreviation .. property_id, request_id, "0")
end

local function blocking_rules()
  return false

  -- Hash
  -- Key: "1.1.1.1" -> "1.1.1.1"
  --      "1.1.1.1/24" -> "1.1.1."
  --      "1.1.1.1/16" -> "1.1."
  --      "1.1.1.1/8" -> "1."


end

local function culling()
  return false
end     

-- Initialize local variables
local current_timebucket = get_time_bucket_from_timestamp(unix_time_milliseconds, false)

-- Request Stream
  -- Adding Request Properties to Hashes
  local ip_id = set_property_value_id_lookups("i", client_ip)
  local ua_id = set_property_value_id_lookups("u", user_agent)
  local path_id = set_property_value_id_lookups("p", path)
  local parameter_id = set_property_value_id_lookups("pa", parameters)
  local host_id = set_property_value_id_lookups("h", host)
  local method_id = set_property_value_id_lookups("m", method)

-- BLOCKING LOGIC
-- TODO: Add blocking logic
  local blocked 

  if blocked_by_rules() == true then
    blocked = 1
    increment_leaderboard_for("b", current_timebucket, request_id)
  else
    blocked = 0    
  end

-- Adding Request Stream
  local stream_id

  if use_timestamps_as_request_ids == true then
      stream_id = unix_time_milliseconds
  else
      stream_id = "*"
  end
  
  local request_id = redis.call("XADD", "rStream", "MAXLEN", "~", max_requests, stream_id, "i", ip_id, "u", ua_id, "p", path_id, "h", host_id, "m", method_id, "up", parameters, "b", blocked)

-- LEADERBOARD DATA COLLECTION
-- using property abbreviation and timebucket
  increment_leaderboard_for("i", current_timebucket, ip_id)
  increment_leaderboard_for("u", current_timebucket, ua_id)
  increment_leaderboard_for("p", current_timebucket, path_id)
  increment_leaderboard_for("h", current_timebucket, host_id)
  increment_leaderboard_for("m", current_timebucket, method_id)

-- Property to Request Hashes
  set_property_to_requests("i", ip_id, request_id, blocked)
  set_property_to_requests("u", ua_id, request_id, blocked)
  set_property_to_requests("p", path_id, request_id, blocked)
  set_property_to_requests("h", host_id, request_id, blocked)
  set_property_to_requests("m", method_id, request_id, blocked)

-- Aggregate Hash Group Counts
-- Used for Graphs and alerting

if blocked == false then
  return "Allowed"
else
  return "Blocked"
end

