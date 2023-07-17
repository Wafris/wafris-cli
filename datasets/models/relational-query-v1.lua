
-- QUERYING LOGIC

local output_data = ""
local current_timestamp = tonumber(redis.call("TIME")[1]) * 1000 -- Get current timestamp

-- How many requests in last 10 minutes
	local ten_minutes_ago = current_timestamp - (60 * 10 * 1000) -- Calculate timestamp 24 hours ago
	local result = redis.call("XRANGE", "requestStream", ten_minutes_ago, "+")
	output_data = "10m: " .. tostring(#result)

-- How many requests in last 12 hours
	local twelve_hours_ago = current_timestamp - (12 * 60 * 60 * 1000) -- Calculate timestamp 24 hours ago
	local result = redis.call("XRANGE", "requestStream", twelve_hours_ago, "+")
	output_data = output_data .. " 12h: " .. tostring(#result)

-- How many requests in last 24 hours
	local twenty_four_hours_ago = current_timestamp - (24 * 60 * 60 * 1000) -- Calculate timestamp 24 hours ago
	local result = redis.call("XRANGE", "requestStream", twenty_four_hours_ago, "+")
	output_data = output_data .. " 24h: " .. tostring(#result)

-- How many requests in last between 7am and 8am
	-- Convert the current timestamp to milliseconds

	-- Get the current day in Redis time format
	local current_day = math.floor(current_timestamp / (24 * 60 * 60 * 1000))

	-- Set the target hours (7am and 8am)
	local target_hour_7am = 7
	local target_hour_8am = 8

	-- Calculate the timestamps for 7am and 8am
	local timestamp_7am = (current_day * (24 * 60 * 60 * 1000)) + (target_hour_7am * 60 * 60 * 1000)
	local timestamp_8am = (current_day * (24 * 60 * 60 * 1000)) + (target_hour_8am * 60 * 60 * 1000)

	local result = redis.call("XRANGE", "requestStream", timestamp_7am, timestamp_8am)

	output_data = output_data .. " 7to8am: " .. tostring(#result)


-- SETUP
	-- Range (start and end timestamps)

-- Dynamic IP leaderboard

	-- Get array of the involved IPs (from 

	-- XRANGE on the 


-- All Requests that an IP made




-- All User Agents that an IP made requests with





	output_data = tostring(count_ua_id) .. "\n" .. output_stream_data

-- How many IPs have made requests
-- IPs and how many requests each has made
-- IPs and how many different UAs each has made requests with




return output_data
