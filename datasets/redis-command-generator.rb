
require 'redis'
require 'faker'
require 'awesome_print'

# FILE GENERATION

# Settings
ENTRY_COUNT = 1000000
IP_COUNT = 50000
PATH_COUNT = 10000
PARAMETERS_COUNT = 100000
USER_AGENT_COUNT = 2500
METHOD_COUNT = 25
HOST_COUNT = 2500
DAYS_AGO_COUNT = 1

# Load script
SCRIPT_SHA = `redis-cli -x script load < models/relational-loader-v1.lua`.chomp
puts "Script Loaded: #{SCRIPT_SHA}"


# Prepare output files
csv_output_file = File.open('consumer-dataset.csv', 'w')
redis_output_file = File.open('redis-commands.txt', 'w')

# Generate Collections
ips = (0..IP_COUNT).map { Faker::Internet.ip_v4_address }
paths = (0..PATH_COUNT).map { Faker::Internet.slug }
parameters = (0..PARAMETERS_COUNT).map { Faker::Internet.slug }
uas = (0..USER_AGENT_COUNT).map { Faker::Internet.user_agent }
methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD', 'TRACE', 'CONNECT', 'PROPFIND']
method_weights = [0.9, 0.05, 0.025, 0.01, 0.005, 0.005, 0.005, 0.005, 0.005, 0.005]

def weighted_random(methods)
  weights = [2, 3, 1, 1, 1, 1, 1, 1, 1, 1]  # Weights corresponding to the methods array

  # Calculate the total weight
  total_weight = weights.sum

  # Generate a random number between 0 and the total weight
  random_number = rand(total_weight)

  # Iterate through the methods and find the corresponding value based on the random number
  cumulative_weight = 0
  methods.each_with_index do |method, index|
    cumulative_weight += weights[index]
    return method if random_number < cumulative_weight
  end
end

# Timestamps need to be sequential, so generate them first
# We generate them _back_ from the current time so the data makes more sense in querying / modeling
timestamp_array = []
current_time_ms = Time.now.utc.to_i * 1000
start_time_ms = current_time_ms - (24 * 60 * 60 * 1000)  # Subtracting 24 hours in milliseconds
interval = (current_time_ms - start_time_ms) / ENTRY_COUNT

(0..ENTRY_COUNT).each do |i|
  timestamp_array << start_time_ms + (i * interval)
end

timestamp_array.reverse!

# Remove any existing data files
Dir.glob("data/*.txt").each do |existing_file|
  File.delete(existing_file)
end

hosts = (0..HOST_COUNT).map { Faker::Internet.domain_name }
chunk_size = 25000
file_index = 0

(0..ENTRY_COUNT).each_slice(chunk_size) do |entries|
  # Open a new file for each chunk
  redis_output_file = File.open("data/redis_commands_#{file_index}.txt", 'w')

  entries.each do |i|
    # IP
    ip = ips.sample

    # Timestamps - generate these sequentially as otherwise they won't work as stream ids
    timestamp_ms = timestamp_array.pop

    # User Agent
    user_agent = uas.sample

    # Path
    path = paths.sample

    parameter = "user-slug=" + parameters.sample.to_s

    # Host
    host = hosts.sample

    # Method
    method = weighted_random(methods)

    # Write to Redis commands file
    # Assume the `script_sha` as "YOUR_SCRIPT_SHA", replace it with your actual sha value.
    redis_output_file.puts "EVALSHA #{SCRIPT_SHA} 0 #{ip} #{timestamp_ms} '#{user_agent}' #{path} #{parameter} #{host} #{method}"
  end

  # Close the current file and increment the file index
  redis_output_file.close
  file_index += 1
end

# Close the files
csv_output_file.close
redis_output_file.close

# LOADING

puts "Relational Model v1"
puts "Clear Redis"

flush = `redis-cli flushall`
puts "Redis flushed: #{flush}"

hmze = 'redis-cli config set hash-max-ziplist-entries 2048' 
puts hmze
system(hmze)

hmzv = 'redis-cli config set hash-max-ziplist-value 256'
puts hmzv
system(hmzv)

start_time = (Time.now.to_f * 1000).to_i

# Load all files in the data directory
Dir.glob("data/*.txt").sort_by{ |f| File.ctime(f) }.each do |existing_file|
	start_file_time = (Time.now.to_f * 1000).to_i 
  system("cat #{existing_file} | redis-cli --pipe")
	end_file_time = (Time.now.to_f * 1000).to_i
	puts "File #{existing_file} loaded in #{end_file_time - start_file_time} ms"
end

status = system("cat redis-commands.txt | redis-cli --pipe")

puts status

# Print the line count
puts "#{ENTRY_COUNT} Requests generated"

elapsed_seconds = ((Time.now.to_f * 1000).to_i - start_time) / 1000.0

puts "Time taken: #{elapsed_seconds} seconds"

puts "#{ENTRY_COUNT / elapsed_seconds} Requests Loaded Per Second"