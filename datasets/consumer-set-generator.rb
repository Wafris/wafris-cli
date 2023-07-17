require 'faker'
require 'awesome_print'

# Settings
ENTRY_COUNT = 1000000
IP_COUNT = 500
PATH_COUNT = 100000
USER_AGENT_COUNT = 250
METHOD_COUNT = 10
HOST_COUNT = 5000
DAYS_AGO_COUNT = 1

output_file = File.open('consumer-dataset.csv', 'w')

# Generate Collections
ips = (0..IP_COUNT).map { Faker::Internet.ip_v4_address }
paths = (0..PATH_COUNT).map { Faker::Internet.uuid }
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

hosts = (0..HOST_COUNT).map { Faker::Internet.domain_name }

(0..ENTRY_COUNT).each do |i|
  # IP
  ip = ips.sample

  # Integer IP
  ip_int = IPAddr.new(ip).to_i

  # Timestamps - generate these sequentially as otherwise they won't work as stream ids
  timestamp_ms = timestamp_array.pop

  # User Agent
  user_agent = uas.sample

  # Path
  path = "foo/bar/?site_api_key=#{paths.sample}"

  # Host
  host = hosts.sample

  # Method
  method = weighted_random(methods)

  # Write to file
  output_file.puts "\"#{ip}\",\"#{ip_int}\",\"#{timestamp_ms}\",\"#{user_agent}\",\"#{path}\",\"#{host}\",\"#{method}\""
end


output_file.close
