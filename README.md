# wp-vps-build-guide
A verbose build guide for a modern, high-performance Wordpress production VPS.

## Intro
I have been tinkering with building WordPress sites for the better part of five years. After getting fed up with typical cheap shared hosting options, I decided to explore the world of VPSs. After using DigitalOcean for a couple years, I have piced together this workflow that I use to spin up new servers. I know that scripting and other modern tools such as what the team at roots.io is working on are out there, but I prefer to understanding the underlying technologies of the server.

If you are an amateur WordPresser like myself, feel free to use this guide to turbocharge your client's sites!

If you are an expert WordPress DevOps type of person, please provide feedback. I'd love to continue to tweak and optimize this stack. I believe this to be a "pretty good" solution, but I know that it is not perfect.

## The Stack
- Dev. Machine: OS X
- Host: DigitalOcean
- Server: Ubuntu x64
- Web Server: nginx
  - w/FastCGI caching
  - w/ngx_pagespeed
- Database: MariaDB
- PHP Processor: HHVM
  - w/php5-fpm failover
- Object Cache: Redis
- TLS w/SPDY: yes (A+ SSL labs)
- IPv4 & IPv6
- Anycast DNS: CloudFlare
- CDN: CloudFlare

## General Notes:
- Items in corner brackets (<>) should be treated as variables and replaced with your own info.
- Scattered throughout I have annotated recommended spots where I like to stop and take a DigitalOcean (DO) Snapshot so I don’t have to roll all the way back if I bork something up.

## Assumptions:
- You have basic *nix terminal skills.
- You have a ssh key already created, with the public key on DO and the private .pem stored locally at <myPK>

1. Create a new VPS running the newest Ubuntu x64.
    - Enable backups.
    - Enable ipv6.
    - Select SSH key.
2. Locally, configure a ssh config file to make ssh easy.
    - In Terminal, `sudo nano ~/.ssh/config`

		```
		Host <myVPSName>
		HostName <myVPSIP>
		Port 22
		User root
		IdentityFile <myPK>
		```

    - ctrl + x to save and exit.