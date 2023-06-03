# wafris-cli
Use the Wafris CLI to set rules and monitor your Wafris instance.

## What's Wafris
Wafris is an open source web application firewall that runs within your existing web framework powered by Redis.

The Wafris CLI (this repository) interacts with a Redis installation to set rules for your Wafris instance.

## How do the pieces fit together?

- **Redis**: the Client sends request data (IP address, Proxy info, User agent, Host, Path, etc.) to the Redis instance where it's evaluated against rules that you have set.  

- **Wafris Client**: an open source framework specific library that is installed in your application.

- **Wafris CLI**: an open source command line tool for setting new Wafris rules (ex: Blocking an IP address) 

- **Wafris Hub**: a free hosted web interface for both the reporting of the traffic coming into your application as well as rule setting, and access management. 

# Using WAFRIS CLI Bash Script: An In-Depth Guide

The WAFRIS CLI is a bash script that lets you interact with your Web Application Firewall (WAF). It offers several features that allow you to manage your IP blocklist and allowlist. This article provides a comprehensive guide on each option flag provided by the `wafris-cli.sh` script.

Before you begin, please ensure that you have the necessary permissions to execute the script. If not, you can provide execute permissions to the script by running the following command in your terminal:

```bash
chmod +x wafris-cli.sh
```

Once you have ensured that the script is executable, you can run it using the following syntax:

```bash
./wafris-cli.sh [OPTIONS]
```

## Understanding the Option Flags

### `-a`: Add IP address to blocklist

This flag allows you to add a specific IP address to the blocklist. This means that the IP address will be blocked from making any requests to your server.

Usage: 

```bash
./wafris-cli.sh -a <IP_ADDRESS>
```

OR


```bash
./wafris-cli -a <IP_ADDRESS>
```


Where `<IP_ADDRESS>` is the IP address that you want to block. Please replace `<IP_ADDRESS>` with the actual IP address.

### `-r`: Remove IP address from blocklist

This flag lets you remove an IP address from the blocklist. The removed IP will no longer be blocked from accessing your server.

Usage: 

```bash
./wafris-cli.sh -r <IP_ADDRESS>
```

Replace `<IP_ADDRESS>` with the IP address that you want to unblock.

### `-A`: Add IP address to allowlist

This flag allows you to add a specific IP address to the allowlist. This IP address will always be permitted to make requests to your server, bypassing the WAF's security filters.

Usage: 

```bash
./wafris-cli.sh -A <IP_ADDRESS>
```

Again, replace `<IP_ADDRESS>` with the IP address you want to allow.

### `-R`: Remove IP address from allowlist

This flag lets you remove an IP address from the allowlist. The removed IP will no longer bypass the WAF's security filters.

Usage: 

```bash
./wafris-cli.sh -R <IP_ADDRESS>
```

Replace `<IP_ADDRESS>` with the IP address that you want to remove from the allowlist.

### `-g`: Get top requesting IPs

This flag provides a list of IP addresses that have made the most requests to your server. This can help identify potential threats or recognize IPs that are accessing your server excessively.

Usage: 

```bash
./wafris-cli.sh -g
```

This command does not require any additional parameters.

### `-b`: Get top blocked IPs

This flag gives you a list of IP addresses that have been blocked the most. It helps you to identify potentially malicious IPs that are repeatedly trying to breach your security.

Usage: 

```bash
./wafris-cli.sh -b
```

This command does not require any additional parameters.

### `-h`: Display the help menu

This flag displays the help menu that provides a brief overview of each option flag. It's a quick way to remember what each flag does.

Usage: 

```bash
./wafris-cli.sh -h
```

No additional parameters are needed for this command.

By understanding and utilizing these options, you can have

