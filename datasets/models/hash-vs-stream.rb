require 'redis'
require 'awesome_print'
require 'faker'
require 'zlib'
flush = `redis-cli flushall`

# defaults
#127.0.0.1:6379> config get hash-*
#1) "hash-max-ziplist-entries"
#2) "512"
#3) "hash-max-listpack-entries"
#4) "512"
#5) "hash-max-listpack-value"
#6) "64"
#7) "hash-max-ziplist-value"
#8) "64"

hmze = 'redis-cli config set hash-max-ziplist-entries 512' 
puts hmze
system(hmze)

hmzv = 'redis-cli config set hash-max-ziplist-value 64'
puts hmzv
system(hmzv)

redis = Redis.new

REQUEST_COUNT = 100000
IP_COUNT = 500

puts "Testing #{REQUEST_COUNT} requests from #{IP_COUNT} IPs"

def generate_fake_request_id
	# Generate a random number between 0 and the total weight	
	return "16896" + rand(1000..9999).to_s + rand(1000..9999).to_s + "-0"
end

request_id_array = (0..REQUEST_COUNT).map { generate_fake_request_id }
ips = (0..IP_COUNT).map { Faker::Internet.ip_v4_address }

ips_request_hash = {}

# Build hash of request ids for each IP
request_id_array.each do |rid|
	ip = ips.sample

	if ips_request_hash[ip].nil?
		ips_request_hash[ip] = [rid]
	else
		ips_request_hash[ip] << rid
	end
end 

# SMAZ
def smaz_compress(input)
  result = []
  dictionary = {}
  pos = 0

  while pos < input.length
    best_length = 0
    best_offset = 0

    (1..[256, pos].min).each do |offset|
      length = 0

      while pos + length < input.length && input[pos - offset, length] == input[pos, length] && length < 256
        length += 1
      end

      if length > best_length
        best_length = length
        best_offset = offset
      end
    end

    if best_length > 2 || (best_length == 2 && best_offset <= 7)
      result << (256 + (best_offset - 1) * 16 + (best_length - 2))
      pos += best_length
    else
      result << input[pos].ord
      dictionary[input[pos, 2]] = true
      pos += 1
    end
  end

  result.pack("C*")
end

# Streams
start_time = Time.now
ips_request_hash.each do |ip, rids|
	redis.pipelined do		
		rids.each_with_index do |rid, i|			
			redis.xadd("ipIdStream#{ip}", { 'r' => rid })
		end
	end
end 

info = redis.info
memory_used = info['used_memory'].to_i
elapsed_time = Time.now - start_time
time_per_request = elapsed_time / REQUEST_COUNT
puts "Memory used by Streams: #{memory_used} bytes #{memory_used / REQUEST_COUNT} bytes per request | #{elapsed_time} seconds | #{time_per_request} seconds per request"




# Per Property Hashes with Grouped Entries
flush = `redis-cli flushall`
start_time = Time.now

ips_request_hash.each do |ip, rids|
	redis.pipelined do
			redis.hset("ipIdHash#{ip}", 'rids', rids.join(',')) 
	end
end 

info = redis.info
memory_used = info['used_memory'].to_i
elapsed_time = Time.now - start_time
time_per_request = elapsed_time / REQUEST_COUNT
puts "Memory used by Per Property Hash (grouped): #{memory_used} bytes #{memory_used / REQUEST_COUNT} bytes per request | #{elapsed_time} seconds | #{time_per_request} seconds per request"




# Global Hashes
flush = `redis-cli flushall`
start_time = Time.now

ips_request_hash.each do |ip, rids|
	redis.pipelined do
		redis.hset("ipIdHash", ip, rids.join(',')) 
	end
end 

info = redis.info
memory_used = info['used_memory'].to_i
elapsed_time = Time.now - start_time
time_per_request = elapsed_time / REQUEST_COUNT
puts "Memory used by Global Property Hashes: #{memory_used} bytes #{memory_used / REQUEST_COUNT} bytes per request | #{elapsed_time} seconds | #{time_per_request} seconds per request"



# Per Property Hashes with Individual Entries
flush = `redis-cli flushall`
start_time = Time.now

ips_request_hash.each do |ip, rids|
	redis.pipelined do

		rids.each_with_index do |rid, i|
			redis.hset("ipIdHash#{ip}", i, rid) 
		end

	end
end 

info = redis.info
memory_used = info['used_memory'].to_i
elapsed_time = Time.now - start_time
time_per_request = elapsed_time / REQUEST_COUNT
puts "Memory used by Per Property Hash (entries): #{memory_used} bytes #{memory_used / REQUEST_COUNT} bytes per request | #{elapsed_time} seconds | #{time_per_request} seconds per request"
