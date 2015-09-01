# wp-vps-build-guide
A verbose build guide for a modern, high-performance WordPress production VPS.

**This guide is a work in progress and is incomplete. Feel free to look it over if you stumble on it, but it is unusable at this point. Incomplete areas are marked with "TODO"**

## Intro
I have been tinkering with building WordPress sites for the better part of five years. After getting fed up with typical cheap shared hosting options, I decided to explore the world of VPSs. After using DigitalOcean for a couple years, I have pieced together this workflow that I use to spin up new servers. I know that scripting and other modern tools such as what the team at <a href="https://roots.io/" target="_blank">Roots</a> is working on are out there, but I prefer understanding the underlying technologies of the server. For the same reason, and because I am cheap, I avoid the newer breed of managed WordPress hosts.

#### If you are an amateur WordPresser...
like myself, feel free to use this guide to turbocharge your client's sites! If you come across any issues when following the guide, feel free to submit an issue or pull request.

#### If you are an expert at WordPress DevOps...
please provide feedback. I'd love to continue to tweak and optimize this stack. I believe this to be a "pretty good" solution, but I know that it is not perfect and the technologies powering it are constantly changing. Issues and pull requests welcome.

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

## General Notes
- Items in curly brackets {} should be treated as variables and replaced with your own info.
- Scattered throughout I have annotated recommended spots where I like to stop and take a DigitalOcean (DO) Snapshot so I don’t have to roll all the way back if I bork something up.

## Assumptions
- You have basic *nix terminal skills.
- You have a ssh key already created, with the public key on DO and the private .pem stored locally at {myPK}.

## Sources
This build guide is constructed from a compilation of sources from all over the web. I have tried to credit sources where I could (using "via"), but I am sure that I left somebody's blog out.

## Build Guide
1. Create a new VPS running the newest Ubuntu x64.
    - Enable backups.
    - Enable ipv6.
    - Select SSH key.
2. Locally, configure a ssh config file to make ssh easy.
    - In Terminal, `sudo nano ~/.ssh/config`

		```
		Host {myVpsName}
		  HostName {myVpsIP}
		  Port 22
		  User root
		  IdentityFile {myPK}
		```

    - Press "ctrl + x" to save and exit.
3. ssh into the new VPS.
	- `ssh {myVpsName}`
		- Type "yes" to continue connecting.
4. Create a new user and add it to the sudo group.
	- `adduser {myUser}`
		- Provide a password.
		- Press "return" repeatedly to accept the rest of the default options.
	- `gpasswd -a {myUser} sudo`
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
5. Copy the root ssh key to the new account.
	- `mkdir /home/{myUser}/.ssh`
	- `cp ~/.ssh/authorized_keys /home/{myUser}/.ssh/`
	- `chown -R {myUser}:{myUser} /home/{myUser}/.ssh`
	- `chmod 700 /home/{myUser}/.ssh`
	- `chmod 600 /home/{myUser}/.ssh/authorized_keys`
	- `nano /etc/ssh/sshd_config`
        - Modify `Port {myRandomSshPort}` (<a href="http://www.wolframalpha.com/input/?i=RandomInteger%281025%2C65536%29" target="_blank">Generate Port</a>)
		- Modify `PermitRootLogin no`
 	- `service ssh restart`
	- Don’t close the Terminal window, yet. In another Terminal window,
    	- `sudo nano ~/.ssh/config`

			```
			Host {myVpsName}
			  HostName {myVpsIP}
			  Port {myRandomSshPort}
			  User {myUser}
			  IdentityFile {myPK}
			```
        
	- Test ssh into the VPS as {myUser} before closing the root Terminal window.
		- `ssh {myVPSName}`
	- Type "exit" in root Terminal window.
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
6. Snapshot 1
	- `sudo poweroff now`
	- Create a Snapshot in the DO control panel.
7. Update all the things and cleanup after yourself.
	- `sudo apt-get update`
	- `sudo apt-get upgrade`
	- `sudo apt-get dist-upgrade`
	- `sudo apt-get autoremove`
	- `sudo apt-get autoclean`
8. Configure a basic firewall with ufw.
	- `sudo ufw allow {myRandomSshPort}/tcp`
	- `sudo ufw allow 80/tcp`
	- `sudo ufw allow 443/tcp`
	- `sudo ufw enable`
		- Type "y" to proceed with operation.
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
9. Update the timezone and configure ntp sync.
	- `sudo dpkg-reconfigure tzdata`
		- Select the local timezone.
	- `sudo apt-get update`
	- `sudo apt-get install ntp`
		- Press "return" to install.
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
10. Enable a swap file of 2x RAM size. (Resize if droplet is ever scaled.)
	- `sudo fallocate -l {swapSizeInGb}G /swapfile`
	- `sudo chmod 600 /swapfile`
	- `sudo mkswap /swapfile`
	- `sudo swapon /swapfile`
	- `sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'`
	- `sudo nano /etc/sysctl.conf`
		- Add `vm.swappiness=10`
		- Add `vm.vfs_cache_pressure=50`
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>, <a href="https://help.ubuntu.com/community/SwapFaq" target="_blank">Ubuntu</a>_
11. Snapshot 2
12. Configure automatic updates, upgrades, & cleanup.
	- `sudo apt-get install unattended-upgrades`
	- `sudo dpkg-reconfigure -plow unattended-upgrades`
		- Select "Yes" to auto-install upgrades.
	- `sudo nano /etc/apt/apt.conf.d/20auto-upgrades`
		- Add `APT::Periodic::Download-Upgradeable-Packages "1";`
		- Add `APT::Periodic::AutocleanInterval "1";`
	- `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
		- Uncomment `"${distro_id}:${distro_codename}-updates";`
		- Uncomment and update `Unattended-Upgrade::Automatic-Reboot "true";`
13. Download, compile, and install nginx w/ngx_pagespeed.
	- `sudo add-apt-repository -s -y ppa:nginx/development`
	- `sudo apt-get update`
	- `sudo apt-get -y build-dep nginx`
	- `sudo mkdir -p /opt/nginx`
	- `sudo chown {myUser}:{myUser} /opt/nginx`
	- `cd /opt/nginx`
	- `sudo apt-get source nginx`
	- `cd nginx-{nginxCurVer}/debian/modules/`
	- `sudo apt-get install unzip`
	- `sudo wget {npsZipLink}` (Copy link to newest zip <a href="https://github.com/pagespeed/ngx_pagespeed/releases" target="_blank">here</a>.)
	- `sudo unzip {npsZipFile}`
	- `sudo rm {npsZipFile}`
	- `cd ngx_pagespeed-{npsCurVer}-beta/`
	- `sudo wget https://dl.google.com/dl/page-speed/psol/{npsCurVer}.tar.gz`
	- `sudo tar -xzvf {npsCurVer}.tar.gz`
	- `sudo rm {npsCurVer}.tar.gz`
	- **TODO**: Download newest OpenSSL and compile with nginx.
	- `sudo nano /opt/nginx/nginx-{npsCurVer}/debian/rules`
		- Under "light" version flags:
			- Delete `--without-ngx_http_limit_req_module`
			- Add `--with-http_spdy_module \`
			- Add `--add-module=$(MODULESDIR)/nginx-cache-purge \`
			- Add `--add-module=$(MODULESDIR)/ngx_pagespeed-{NpsCurVer}-beta`
	- `cd /opt/nginx/nginx-{nginxCurVer}/`
	- `sudo dpkg-buildpackage -b`
	- `cd /opt/nginx/`
	- `sudo dpkg -i nginx_{nginxCurVer}+trusty0_all.deb nginx-common_{nginxCurVer}+trusty0_all.deb nginx-doc_{nginxCurVer}+trusty0_all.deb nginx-light_{nginxCurVer}+trusty0_amd64.deb`
		- If there are dependency errors due to python:
        	- `sudo apt-get -f install`
	- `sudo rm -rf /opt/nginx/`
	- `echo "nginx-light hold" | sudo dpkg --set-selections`
	- Verify nginx is installed by visiting {myVpsIP} in a browser.
	- `sudo nano /etc/nginx/nginx.conf`
    	- **TODO**: Insert link to nginx.conf here.
	- _via <a href="https://github.com/h5bp/server-configs-nginx/blob/master/nginx.conf" target="_blank">h5bp</a>, <a href="https://blog.rudeotter.com/nginx-modules-pagespeed-ubuntu/" target="_blank">Rude Otter</a>_
14. **TODO**: Work in progress...
99. TBD
	- Delete ufw rule for port 80 once full-site TLS is configured.

## Ongoing Maintenance
- Whenever nginx, ngx_pagespeed, or OpenSSL have a new release, repeat step 13.