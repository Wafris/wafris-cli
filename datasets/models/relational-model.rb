require 'csv'

puts "Relational Model v1"
puts "Clear Redis"

# Path to the CSV file
csv_file = "consumer-dataset.csv"

# Get the number of lines in the file
line_count = File.foreach(csv_file).count

# Print the line count
puts "#{line_count} Requests from #{csv_file}"

# Start Time
start_time = (Time.now.to_f * 1000).to_i

flush = `redis-cli flushall`
puts "Redis flushed: #{flush}"

# Load script
script_sha = `redis-cli -x script load < models/relational-loader-v1.lua`.chomp
puts "Script Loaded: #{script_sha}"

# Start the redis-cli pipeline
redis_cli_pipeline = []
redis_cli_pipeline << "MULTI"

ua_arr = []

i  = 0
# Loop over each line in the CSV file
CSV.foreach(csv_file) do |line|

  i = i + 1

  if (i % 1000 == 0)
    puts "Processed #{i} lines"
  end

  ip, ip_int, timestamp_ms, user_agent, path, hostname, method = line.map(&:strip)

  # Enclose user_agent argument in quotes
  redis_command = "EVALSHA #{script_sha} 0 '#{ip}' '#{ip_int}' '#{timestamp_ms}' \"'#{user_agent}'\" '#{path}' '#{hostname}' '#{method}'"

  output = `redis-cli #{redis_command}`
end



puts ""
puts "LOAD COMPLETE"
load_complete_time = (Time.now.to_f * 1000).to_i

# Start Querying
`redis-cli --eval models/relational-query-v1.lua`

puts ""
puts "QUERY COMPLETE"
query_complete_time = (Time.now.to_f * 1000).to_i

# Get Redis memory statistics
redis_stats = `redis-cli info memory`

# Print the relevant memory statistics
puts ""
puts "REDIS MEMORY STATS:"
used_memory_human = redis_stats.match(/used_memory_human:(.*)/)[1].strip
used_memory_peak = redis_stats.match(/used_memory_peak_human:(.*)/)[1].strip
used_memory_lua = redis_stats.match(/used_memory_lua_human:(.*)/)[1].strip

puts "Used Memory: #{used_memory_human}"
puts "Used Memory Peak: #{used_memory_peak}"
puts "Used Memory Lua: #{used_memory_lua}"

# Get Redis keyspace info using redis-cli
keyspace_info = `redis-cli info keyspace`

# Print the keyspace info
puts ""
puts "REDIS KEY STATS:"
puts keyspace_info

puts ""
puts "REQUEST MEMORY EFFICIENCY:"

# Get memory used by Redis
memory = `redis-cli info memory | grep "used_memory:" | cut -d':' -f2`.strip.to_i

# Perform the division
memory_per_request = memory / line_count.to_f

puts "Number of requests made: #{line_count}"
puts "Memory per request: #{memory_per_request} bytes"

puts ""
puts "REQUEST TIME EFFICIENCY:"

load_time = load_complete_time - start_time
puts "Time to load requests: #{load_time} ms"

request_load_time = load_time / line_count.to_f
puts "MS per Request Load: #{request_load_time} ms"

query_time = query_complete_time - load_complete_time
puts "Time to query requests: #{query_time} ms"

request_query_time = query_time / line_count.to_f
puts "MS per Request query: #{request_query_time} ms"

puts ""
puts "MODEL PERFORMANCE STATS:"
puts "Memory Per Request (MPR): #{memory_per_request} bytes"
puts "Request Load Time (RLT): #{request_load_time} ms"
puts "Request Query Time (RQT): #{request_query_time} ms"
