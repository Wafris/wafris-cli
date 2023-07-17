require 'time'
require 'redis'
require 'awesome_print'

# The below corresponds to the reporting queries at:
# https://whimsical.com/full-redis-data-model-UYsMg2xRehUNjci8TfUaf

# Generate a hash of timestamps, going back a specified number of hours
# The hash is in the format: { "2021-01-01 00:00:00 UTC" => [1609459200000, 1609462800000] }
# values are [start, end] timestamps in milliseconds and used for XRANGE queries
# timestamps are:
# - milliseconds
# - start of the hour
# - UTC
# - descending order
def generate_timestamps_hash(hours_back)
  timestamps = {}
  current_time = Time.now.utc
  start_of_hour = Time.new(current_time.year, current_time.month, current_time.day, current_time.hour, 0, 0)

  hours_back.downto(0) do |hours|
    timestamp = start_of_hour - (hours * 60 * 60)
    timestamps[timestamp.to_s] = [timestamp.to_i * 1000, (timestamp + 1 * 60 * 60).to_i * 1000]
  end

	# Descending order
  timestamps.reverse_each.to_h
end

def make_xrange_queries(timestamps_hash)
  redis = Redis.new
  results = {}

	# There's a large optimization to be made here by using a lua script instead
	# that would allow us to call `#result` on the range in lua/redis and get the count 
	# where here we are actually returning the entire array and then counting it
  redis.pipelined do
    timestamps_hash.each do |timestamp, _|
      start_time = timestamps_hash[timestamp][0]
      end_time = timestamps_hash[timestamp][1]

      result = redis.xrange('requestsStream', start_time, end_time)  
      count = result.length

      results[timestamp] = count
    end
  end

  return results
end


metric_time_start = Time.now

puts "1. Dynamic Graph Data for Requests"
	timestamps_hash = generate_timestamps_hash(24)
	#ap timestamps_hash

	query_results = make_xrange_queries(timestamps_hash)

	# Use the query_results later in your application
	query_results.each do |timestamp, count|
		puts "\t#{timestamp}: #{count} records"
	end

	part_one_time = Time.now
	puts "\tTotal time: #{part_one_time - metric_time_start}"

puts "2. Brute force Grouped Property Count Intervals (Leaderboard)"
	puts "\tAll requests from last 24hrs grouped by UA_ID"
	current_time_ms = Time.now.utc.to_i * 1000

	redis = Redis.new
	# '-' is the smallest possible value, so this will return all records
	requests = redis.xrange('requestsStream', '-', '+')  

	p2_redis_end_time = Time.now
	puts "\tRedis query time: #{p2_redis_end_time - part_one_time}"

	# Request is an array of arrays
	# Each sub-array is [stream_id, { hash of properties }]

	ua_group_count = {}

	requests.each do |request|		
		ua_id = request[1]['ua_id']
		ua_group_count[ua_id] ||= 0  # Initialize count to 0 if ua_id is not already in the hash
		ua_group_count[ua_id] += 1  # Increment the count for ua_id
	end

	ap ua_group_count

	part_two_time = Time.now
	puts "\tRuby caclulation time: #{part_two_time - p2_redis_end_time}"


puts "3. Request Property Counts by IP"



puts "4. Requests from a property (ex: UA)"

	part_four_time = Time.now.to_i


	redis = Redis.new
	end_time = Time.now.utc.to_i * 1000
	start_time = (Time.now.utc - (60 * 60 * 12)).to_i * 1000

	result = redis.xrange('ua-to-request-stream:3', start_time, end_time)
	ua_request_ids = result.map! { |r| r[1]['r_id'] }

	#ap result

	puts "\tFound: " + result.length.to_s + " requests from UA_ID 3"


puts "5. Requests with multiple property filters (ex: intersection of UA and IP)"

redis = Redis.new
end_time = Time.now.utc.to_i * 1000
start_time = (Time.now.utc - (60 * 60 * 12)).to_i * 1000

result = redis.xrange('path-to-request-stream:78114', start_time, end_time)
path_request_ids = result.map! { |r| r[1]['r_id'] }

puts "\tFound: " + path_request_ids.size.to_s + " requests from PATH_ID 78114"

ua_and_path_request_ids = ua_request_ids & path_request_ids

puts "\tFound: " + ua_and_path_request_ids.size.to_s + " requests from Intersection of UA_ID 3 and PATH_ID 78114"

puts "\tP3 and P4 time: #{Time.now.to_i - part_four_time}"


ap ua_and_path_request_ids