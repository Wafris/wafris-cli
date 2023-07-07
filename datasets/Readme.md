# Dataset

## Purpose & Context

This repo contains experiments, prototypes and throwaway code. 

It's intended as a playground for us to rapidly answer questions about how different modeling approaches might work in Redis.

## Criteria

All models are flawed, but some are useful and in setting this up here's the three useful criteria I've found:

1. Memory Per Request (MPR) - Redis 'used memory' stat divided by the number of requests made. 

2. Request Load Time (RLT) - the time (in milliseconds) that it takes to run the loading script divided by the number of requests.

3. Request Query Time (RQT) - the time (in milliseconds) that it takes to run the query script divided by the number of requests.


## How to Use




## API Set

This set is designed to test performance with a few IP addresses making many requests. 

It's most similar to an early ExpWAF customer who has licensing software installed in a couple dozen factories around the world with each site basically making request a second.

Requests are very simple (pass in a unique api key and test the response)

1,000,000 requests with:

- Consistent Request timing
- 24 IPs
- 10 unique Paths
- 1 User Agent 
- 1 Method GET
- 1 Host

All requests were from custom Java software with a fixed UserAgent 

## Consumer Set

This is what I think of Monica Lent's Affilimate or Josh's Referral Rock. 

Tons and tons of unique requests combinations from very high traffic sites with very distributed request patterns. 

1,000,000 requests with:

- Spiky and Daytime weighted request timing
- 500,000 IPs
- 100,000 unique Paths
- 250 User Agents (spread in popularity)
- 10 Methods (spread in popularity)
- 5,000 Hosts 

## Data Generation

- Generation is done with Faker




