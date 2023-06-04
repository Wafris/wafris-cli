# wafris-cli
Use the Wafris CLI to set rules and monitor your Wafris instance.

## What's Wafris
Wafris is an open-source web application firewall that runs within your existing web framework powered by Redis.

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

## Connecting to Redis



## Understanding the Option Flags

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

### `-A`: Add IP address to allowlist

This flag allows you to add a specific IP address to the allowlist. This IP address will always be permitted to make requests to your server, bypassing the WAF's security filters.

Usage: 

```bash
./wafris -A <IP_ADDRESS>
```

Again, replace `<IP_ADDRESS>` with the IP address you want to allow.

### `-R`: Remove IP address from allowlist

This flag lets you remove an IP address from the allowlist. The removed IP will no longer bypass the WAF's security filters.

Usage: 

```bash
./wafris -R <IP_ADDRESS>
```

Replace `<IP_ADDRESS>` with the IP address you want to remove from the allowlist.

### `-g`: Get top requesting IPs

This flag lists IP addresses that have made the most requests to your server. This can help identify potential threats or recognize IPs accessing your server excessively.

Usage: 

```bash
./wafris -g
```

This command does not require any additional parameters.

### `-b`: Get top blocked IPs

This flag gives you a list of IP addresses that have been blocked the most. It helps you identify potentially malicious IPs repeatedly trying to breach your security.

Usage: 

```bash
./wafris -b
```

This command does not require any additional parameters.

### `-h`: Display the help menu

This flag displays the help menu, providing a brief overview of each option flag. It's a quick way to remember what each flag does.

Usage: 

```bash
./wafris -h
```

No additional parameters are needed for this command.

By understanding and utilizing these options, you can have


## FAQ & Troubleshooting


### What permissions does this need?

Before you begin, please ensure that you have the necessary permissions to execute the script. If not, you can set execute permissions to the script by running the following command in your terminal:

```bash
chmod +x wafris
```

### Why can't I connect to Redis?

1. You should make sure Redis is running, and you can connect to it locally
2. Make sure that `redis-cli` is installed and in your path
3. Double-check that you've correctly set Redis connection information in the `config.env` file - on some providers (Heroku), they periodically change the host and port that Redis is on. You may need to update your configuration.
