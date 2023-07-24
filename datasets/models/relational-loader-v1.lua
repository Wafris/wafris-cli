
-- FUNCTIONS DECLARED FIRST



-- Takes a timestamps and returns the timebucket
-- parameter is a timestamp label in seconds
-- a timebucket label is just another timestamp in seconds
local startOfHourTimestamp = 0
local function get_timebucket(timestamp_in_seconds)  
  startOfHourTimestamp = math.floor(timestamp_in_seconds / 3600) * 3600
  return startOfHourTimestamp
end

-- Request Property Loading and Mapping
local function set_property_value_id_lookups(property_abbreviation, property_value, expiration)

  -- Checks if the key already exists in the property hash
  -- the name ("ip") has a value (ex: "1.2.3.4") to the property id (ex: 1)
  local property_id
  
  property_id = redis.call("HGET", property_abbreviation .. "-v-id", property_value)

  -- if the property id exists update the expiration
  if property_id == false then
    property_id = redis.call("INCR", property_abbreviation .. "-id-counter")
    redis.call("HSET", property_abbreviation .. "-v-id", property_value, property_id)
    redis.call("HSET", property_abbreviation .. "-id-v", property_id, property_value)
  else
    redis.call("EXPIRE", property_abbreviation .. "-v-id", expiration)
    redis.call("EXPIRE", property_abbreviation .. "-id-v", expiration)
  end

  return property_id
end

-- Leaderboards: Listing of properties and how many requests in a timebucket
local function increment_leaderboard_for(property_abbreviation, property_id, timebucket)
  local key = property_abbreviation .. "L" .. timebucket
  redis.call("ZINCRBY", key, 1, property_id)
  -- Expire the key after 25 hours if it has no expiry
  redis.call("EXPIRE", key, 86400)
end

local function encodeRequestId(full_request_id)
  
  -- Split the input at "-"
  local parts = {}
  for part in full_request_id:gmatch("[^-]+") do
      table.insert(parts, part)
  end

  local asciiCodes = {} -- Table to store the ASCII codes of the first part

  -- Loop through the first part of the input two characters at a time
  local firstPart = string.sub(parts[1], 2)
  for i = 1, #firstPart, 2 do
      local twoChars = string.sub(firstPart, i, i + 1)
      local asciiCode = (tonumber(twoChars) - 1) + 128
      table.insert(asciiCodes, asciiCode)
  end

  -- Convert ASCII codes to characters
  local characters = {}
  for _, code in ipairs(asciiCodes) do
      table.insert(characters, string.char(code))
  end

  -- Append the last part of the input to the returned value
  local result = table.concat(characters) .. parts[2]

  return result
end


-- Creates a hash for each unique property and adds request ids as entries
local function set_property_to_requests(property_abbreviation, property_id, request_id, timebucket)
  -- redis.call("LPUSH", property_abbreviation .. "R" .. property_id .. "-" .. timebucket, request_id)
    local existing_value = redis.call("HGET", property_abbreviation .. "R" .. "-" .. timebucket, property_id)

    local encoded_id = encodeRequestId(request_id)

    if existing_value == false then
      redis.call("HSET", property_abbreviation .. "R" .. "-" .. timebucket, property_id, encoded_id)
    else 
      redis.call("HSET", property_abbreviation .. "R" .. "-" .. timebucket, property_id, existing_value .. "," .. encoded_id)
    end
    
  -- Expire the key after 25 hours if it has no expiry
  redis.call("EXPIRE", property_abbreviation .. "R" .. property_id .. "-" .. timebucket, 86400)
end

local function blocking_rules()
  return false

  -- Hash
  -- Key: "1.1.1.1" -> "1.1.1.1"
  --      "1.1.1.1/24" -> "1.1.1."
  --      "1.1.1.1/16" -> "1.1."
  --      "1.1.1.1/8" -> "1."


end


-- CONFIGURATION

-- System Settings
local max_requests_stream_size = 100000
local use_timestamps_as_request_ids = true
local expiration_in_seconds = 86400

-- Values Passed in from the Request
local client_ip = ARGV[1]
local request_ts_in_milliseconds = ARGV[2]
local user_agent = ARGV[3]
local path = ARGV[4]
local parameters = ARGV[5]
local host = ARGV[6]
local method = ARGV[7]
local headers = ARGV[8]
local post_body = ARGV[9]


-- Initialize local variables
local request_ts_in_seconds = ARGV[2] / 1000
local current_timebucket = get_timebucket(request_ts_in_seconds, false)


-- Request Stream
  -- Adding Request Properties to Hashes
  local ip_id = set_property_value_id_lookups("i", client_ip, expiration_in_seconds)
  local ua_id = set_property_value_id_lookups("u", user_agent, expiration_in_seconds)
  local path_id = set_property_value_id_lookups("p", path, expiration_in_seconds)
  local parameters_id = set_property_value_id_lookups("a", parameters, expiration_in_seconds)
  local host_id = set_property_value_id_lookups("h", host, expiration_in_seconds)
  local method_id = set_property_value_id_lookups("m", method, expiration_in_seconds)

-- BLOCKING LOGIC
-- TODO: Add blocking logic
  local blocked 

  if blocking_rules() == true then
    blocked = 1
    increment_leaderboard_for("b", current_timebucket, request_id)
  else
    blocked = 0
  end

-- Adding Request Stream
  local stream_id

  if use_timestamps_as_request_ids == true then
      stream_id = request_ts_in_milliseconds
  else
      stream_id = "*"
  end
  
  -- Request ID is the timestamp in milliseconds 
  local request_id = redis.call("XADD", "rStream", "MAXLEN", "~", max_requests_stream_size, stream_id, "i", ip_id, "u", ua_id, "p", path_id, "h", host_id, "m", method_id, "a", parameters_id, "b", blocked)
  
  -- Add to Requests Count hash to precalc aggregate counts by hour
  redis.call("HINCRBY", "rCounts", current_timebucket, 1)


-- LEADERBOARD DATA COLLECTION
-- using property abbreviation and timebucket
  increment_leaderboard_for("i", ip_id, current_timebucket)
  increment_leaderboard_for("u", ua_id, current_timebucket)
  increment_leaderboard_for("p", path_id, current_timebucket)
  increment_leaderboard_for("a", parameters_id, current_timebucket)
  increment_leaderboard_for("h", host_id, current_timebucket)
  increment_leaderboard_for("m", method_id, current_timebucket)

-- Property to Request Hashes
  set_property_to_requests("i", ip_id, request_id, current_timebucket)
  set_property_to_requests("u", ua_id, request_id, current_timebucket)
  set_property_to_requests("p", path_id, request_id, current_timebucket)
  set_property_to_requests("a", parameters_id, request_id, current_timebucket)
  set_property_to_requests("h", host_id, request_id, current_timebucket)
  set_property_to_requests("m", method_id, request_id, current_timebucket)

-- Aggregate Hash Group Counts
-- Used for Graphs and alerting

if blocked == false then
  return "Allowed"
else
  return "Blocked"
end

