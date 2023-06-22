# Wafris CLI

## What's Wafris?
Wafris is an open-source Web Application Firewall (WAF) that runs within your existing web framework powered by Redis.

Need a better explanation: read 30s overview at: [wafris.org/start](https://wafris.org/start)

## What's the Wafris CLI (this repository)

Wafris CLI lets you set rules and monitor your Wafris instance.

Using the Wafris CLI is optional as for most use cases it's significantly easier to analyze your traffic and set in Wafris Hub at [https://wafris.org/hub](https://wafris.org/hub). 

The CLI tool is primarily useful as:

- An "API" for performing automatic rule setting. Ex: Adding thousands of IP address from a text file to be blocked.

- A tool for managing your Wafris instances in cases where the Redis database backing it can't be reached. 

- A guarantee of our commitment to Open Source and unencumbered security applications.

The Wafris CLI (this repository) interacts with a Redis installation to set rules for your Wafris instance.

## How do the pieces fit together?

- **Redis**: the Client sends request data (IP address, Proxy info, User agent, Host, Path, etc.) to the Redis instance, where it's evaluated against rules that you have set.  

- **Wafris Client**: an open-source framework-specific library installed in your application.

- **Wafris CLI**: an open-source command line tool for setting new Wafris rules (ex: Blocking an IP address) 

- **Wafris Hub**: a free hosted web interface for reporting the traffic coming into your application and rule setting and access management. 

## Using Wafris CLI

Wafris CLI is a utility that lets you interact with your Web Application Firewall (WAF). It offers several features that allow you to manage your IP blocklist and allowlist rules.

```bash
./wafris [OPTIONS]
```

## Getting Started

### Prerequisites

- Wafris client added to your web application
- A Redis server
- Locally installed Redis CLI tools

### 1. Download the CLI 

Download a zip of the Wafris CLI tool:

[Download latest]()

### 2. Connecting to Redis

In the unzipped 'wafris-cli' folder modify the config.env file found within to set the credentials of your Redis instance. 

Note: please don't check .env files (our included) into source control.

### 3. Check your config

At the command line, navigate to the `wafris-cli` directory and run

```bash
./wafris -c
```

If everything passes you should see someting like the following.

```text
→ Checking Redis CLI
 ✔️ Redis CLI is installed.
 ✔️ Redis CLI version is 7.0.8, which meets the minimum requirement of 6 or higher.

→ Checking Redis Server
 ✔️ Successfully connected to Redis server at localhost:6379.
 ✔️ Redis server version is 7.0.8, which meets the minimum requirement of 6 or higher.

🎉 All checks passed. You're good to go!

```

## Wafris CLI command options

### `-a`: Add IP address to the blocklist

This flag allows you to add a specific IP address to the block list, preventing further requests from that address from accessing your application.

Usage: 

```bash
./wafris -a <IP_ADDRESS>
```

Where `<IP_ADDRESS>` is the IP address you want to block. Please replace `<IP_ADDRESS>` with the actual IP address.

### `-r`: Remove the IP address from the blocklist

This flag lets you remove an IP address from the blocklist, allowing that IP to  The removed IP will no longer be blocked from accessing your server.

Usage: 

```bash
./wafris -r <IP_ADDRESS>
```

Replace `<IP_ADDRESS>` with the IP address you want to unblock.

### `-c`: Check configuration

This flag runs the CLI requirements and configuration check.

Usage: 

```bash
./wafris -c 
```


### `-h`: Display the help menu

This flag displays the help menu, providing a brief overview of each option flag. It's a quick way to remember what each flag does.

Usage: 

```bash
./wafris -h
```

No additional parameters are needed for this command.

By understanding and utilizing these options, you can have


## FAQ & Troubleshooting

### Q: What permissions does this need?

Before you begin, please ensure that you have the necessary permissions to execute the script. If not, you can set execute permissions to the script by running the following command in your terminal:

```bash
chmod +x wafris
```

### Q: Why can't I connect to Redis?

1. You should make sure Redis is running, and you can connect to it via your `redis-cli` tools.
2. Make sure that `redis-cli` is installed and in your path
3. Double-check that you've correctly set Redis connection information in the `config.env` file - on some providers (Heroku), they periodically change the host and port that Redis is on. You may need to update your configuration.

### Q: How can I get help?

Email [support@wafris.org](mailto:support@wafris.org) or book a time at https://app.harmonizely.com/expedited/wafris




