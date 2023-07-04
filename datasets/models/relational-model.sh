
echo "Relational Model v1"
echo "Clear Redis"

# Path to the CSV file
csv_file="consumer-dataset.csv"

# Get the number of lines in the file
line_count=$(wc -l < "$csv_file")

# Print the line count
echo "$line_count Requests from $csv_file"

# Utility Functions

# Function to calculate and display the time difference
display_time_difference() {
    start_time=$1
    description=$2

    # Calculate the time difference in seconds
    end_time=$(date +%s.%N)
    elapsed_time=$(echo "$end_time - $start_time" | bc)

    # Print the time difference along with the description
    echo "$description: $elapsed_time seconds"
}

# Start the timer
start_time=$(date +%s.%N)

flush=$(redis-cli flushall)
echo "Redis flushed: $flush"

# Load script
script_sha=$(redis-cli -x script load < models/relational-v1.lua)
echo "Script Loaded: $script_sha"


# Start the redis-cli pipeline
{
  echo "MULTI"
  
  # Loop over each line in the CSV file
  while IFS=',' read -r ip ip_int timestamp timestamp_ms user_agent path hostname method; do
      echo "EVALSHA $script_sha 0 $ip $ip_int $timestamp $timestamp_ms $user_agent $path $hostname $method"
  done < "$csv_file"
  
  echo "EXEC"
} | redis-cli -r 10000 > /dev/null


# Final Time
display_time_difference "$start_time" "Time to Load Requests"

echo ""
echo "RUN COMPLETE"

# Get Redis memory statistics
redis_stats=$(redis-cli info memory)

# Print the relevant memory statistics

echo "Redis Memory Statistics:"
echo "$redis_stats" | grep -E 'used_memory_human:|used_memory_peak_human:'

# Get Redis keyspace info using redis-cli
keyspace_info=$(redis-cli info keyspace)

# Print the keyspace info
echo ""
echo "Redis Keyspace Info:"
echo "$keyspace_info"


# Final Time
echo ""
display_time_difference "$start_time" "Total Time"


