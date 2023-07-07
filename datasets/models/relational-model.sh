
echo "Relational Model v1"
echo "Clear Redis"

# Path to the CSV file
csv_file="consumer-dataset.csv"

# Get the number of lines in the file
line_count=$(wc -l < "$csv_file")

# Print the line count
echo "$line_count Requests from $csv_file"

# Start Time (this seems insane but Macs don't have a good way to get milliseconds)
start_time=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')

flush=$(redis-cli flushall)
echo "Redis flushed: $flush"

# Load script
script_sha=$(redis-cli -x script load < models/relational-loader-v1.lua)
echo "Script Loaded: $script_sha"

# Start the redis-cli pipeline
# there's a bug here with bash handling of the CSV where it's not bringing in the full user agent
{
  echo "MULTI"
  
  # Loop over each line in the CSV file
  while IFS=',' read -r ip ip_int timestamp timestamp_ms user_agent path hostname method; do
      echo "EVALSHA $script_sha 0 $ip $ip_int $timestamp $timestamp_ms $user_agent $path $hostname $method"
  done < "$csv_file"
  
  echo "EXEC"
} | redis-cli > /dev/null


echo ""
echo "LOAD COMPLETE"
load_complete_time=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')

# Start Querying
redis-cli --eval models/relational-query-v1.lua

echo ""
echo "QUERY COMPLETE"

query_complete_time=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')

# Get Redis memory statistics
redis_stats=$(redis-cli info memory)

# Print the relevant memory statistics
echo ""
echo "REDIS MEMORY STATS:"
redis_stats=$(redis-cli info memory)
used_memory_human=$(echo "$redis_stats" | awk -F ':' '/used_memory_human:/ {print $2}')
used_memory_peak=$(echo "$redis_stats" | awk -F ':' '/used_memory_peak_human:/ {print $2}')
used_memory_lua=$(echo "$redis_stats" | awk -F ':' '/used_memory_lua_human:/ {print $2}')

echo "Used Memory: $used_memory_human"
echo "Used Memory Peak: $used_memory_peak"
echo "Used Memory Lua: $used_memory_lua"

# Get Redis keyspace info using redis-cli
keyspace_info=$(redis-cli info keyspace)

# Print the keyspace info
echo ""
echo "REDIS KEY STATS:"
echo "$keyspace_info"

echo ""
echo "REQUEST MEMORY EFFICIENCY:"

# Get memory used by Redis
memory=$(redis-cli info memory | grep "used_memory:" | cut -d':' -f2)

# Perform the division
memory_per_request=$(bc <<< "scale=2; $memory / $line_count")

echo "Number of requests made: $line_count"
echo "Memory per request: $memory_per_request bytes"

echo ""
echo "REQUEST TIME EFFICIENCY:"

load_time=$((load_complete_time - start_time))
echo "Time to load requests: $load_time ms"

request_load_time=$(bc <<< "scale=3; $load_time / $line_count")
echo "MS per Request Load: $request_load_time ms"

query_time=$((query_complete_time - load_complete_time))
echo "Time to query requests: $query_time ms"

request_query_time=$(bc <<< "scale=3; $query_time / $line_count")
echo "MS per Request query: $request_query_time ms"

echo ""
echo "MODEL PERFORMANCE STATS:"
echo "Memory Per Request (MPR): $memory_per_request bytes"
echo "Request Load Time (RLT): $request_load_time ms"
echo "Request Query Time (RQT): $request_query_time ms"

