require 'faker'

ENTRY_COUNT = 15000
IP_COUNT = 24
PATH_COUNT = 10
DAYS_AGO_COUNT = 1

# Generate Collections
ips = (0..IP_COUNT).map { Faker::Internet.ip_v4_address }
api_keys = (0..PATH_COUNT).map { Faker::Internet.uuid }

output_file = File.open('api-dataset.csv', 'w')

(0..ENTRY_COUNT).each do |i|
  # IP
  ip = ips.sample

  # Integer IP
  ip_int = IPAddr.new(ip).to_i

  # Timestamp
  current_time = Time.now.utc
  timestamp_ms = Faker::Time.between(from: current_time - DAYS_AGO_COUNT, to: current_time).to_f * 1000

  # User Agent
  user_agent = "Java-http-client/11.0.6"

  # Path
  path = "foo/bar/?api_key=#{api_keys.sample}"

  # Host
  host = "api-set.example.com"

  # Method
  method = 'GET'

  # Write to file
  output_file.puts "#{ip},#{ip_int},#{timestamp_ms},#{user_agent},#{path},#{host},#{method}"
end

output_file.close
