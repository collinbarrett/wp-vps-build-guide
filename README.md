# wp-vps-build-guide
A verbose build guide for a modern, high-performance WordPress production VPS.

**This guide is a work in progress. Feel free to look it over, but it is currently incomplete.**

## Intro
This project aims to provide a straightforward, albeit lengthy, all-inclusive build guide for a low-budget, high-performance WordPress hosting solution. For as little as $5/mo., one can develop a cutting edge hosting stack for his or her projects. The instructions are verbose so that developers with little server administration experience can track.

#### Scope
This stack is designed for any WordPress site (including multisite or multiple sites) with light to medium loads. It will scale well, but it is not designed for an ultra-heavy use case that requires load balancing across multiple servers, etc. Server configurations are not a one-size-fits-all solution, for sure, but hopefully this guide serves as a "good-enough-for-most" solution. While configuration recommendations provided are a good starting point, it is no substitution for ongoing testing. Both speed and security have been key values during the development of this guide. This guide is scoped to only cover a single self-contained VPS. No load-balancing or CDN configuration is described, while these are highly recommended.

#### To amateurs at WordPress DevOps...
feel free to use this guide to turbocharge projects! Please submit issues or pull requests for any problems discovered.

#### To experts at WordPress DevOps...
please provide feedback. This guide should continue to receive ongoing optimizations and updates. In its current state, it will lead to a server that is higher-performing than most, but it is not perfect and the technologies powering it are constantly changing. Issues and pull requests are welcome.

## The Stack
- Client: OS X
- Host: DigitalOcean
- Server: Ubuntu LTS x64
- Web Server: nginx
  - w/FastCGI microcaching
  - w/ngx_pagespeed
- Database: MariaDB
  - w/Query Cache
- PHP Processor: HHVM
  - w/php7.0-fpm failover
- Object Cache: Redis
- Let's Encrypt TLS
- HTTP/2
- IPv4 & IPv6

## General Notes
- Items in curly brackets {} should be treated as variables and replaced with custom info.
- Recommended Snapshot points are annotated throughout, but feel free to take these more or less frequently.

## Assumptions
- The developer has basic *nix terminal skills.
- The developer has access to a VPS host. DigitalOcean (DO) is used for the purposes of this guide, but competitors such as Linode work just fine.
- The developer has a ssh key already created with the public key stored with the host and the private .pem stored locally at {myPK}.

## Sources
This build guide is constructed from a compilation of sources from all over the web. Inline "via"s give credit to some of these authors, but apologies go out to any blogs that were forgotten.

## Support
The best way to support this project is to submit issues and pull requests to assist in keeping the guide up-to-date. Clicking through the maintainer's <a href="http://brrt.co/CBDigitalOcean" target="_blank">DigitalOcean affiliate link</a> when signing up is helpful as well, but by no means expected.

## Build Guide
1. Create a new VPS running Ubuntu LTS x64.
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
		- Provide {myUserPassword}.
		- Press "return" repeatedly to accept the rest of the default options.
	- `gpasswd -a {myUser} sudo`
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
5. Copy the ssh key to the new user.
	- `mkdir /home/{myUser}/.ssh`
	- `cp ~/.ssh/authorized_keys /home/{myUser}/.ssh/`
	- `chown -R {myUser}:{myUser} /home/{myUser}/.ssh`
	- `chmod 700 /home/{myUser}/.ssh`
	- `chmod 600 /home/{myUser}/.ssh/authorized_keys`
	- `nano /etc/ssh/sshd_config`
        - Modify `Port {myRandomSshPort}` (<a href="http://www.wolframalpha.com/input/?i=RandomInteger%281025%2C65536%29" target="_blank">Generate {myRandomSshPort}</a>)
		- Modify `PermitRootLogin no`
        - Uncomment and modify `PasswordAuthentication no`
 	- `service ssh restart`
	- Don’t close the Terminal window, yet. In another Terminal window:
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
	- Type "exit" in the root Terminal window.
	- _via <a href="https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04" target="_blank">DigitalOcean</a>_
6. Snapshot 1
	- `sudo poweroff`
	- Create a Snapshot in the DO control panel.
7. Update all the things and tidy up.
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
		- Type "y" to proceed with the operation.
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
9. Update the timezone and configure ntp sync.
	- `sudo dpkg-reconfigure tzdata`
		- Select the local timezone.
	- `sudo apt-get update`
	- `sudo apt-get install ntp`
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>_
10. Enable a swap file of 2x RAM size.
	- `sudo fallocate -l {swapSizeInGb}G /swapfile`
	- `sudo chmod 600 /swapfile`
	- `sudo mkswap /swapfile`
	- `sudo swapon /swapfile`
	- `sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'`
	- _via <a href="https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers" target="_blank">DigitalOcean</a>, <a href="https://help.ubuntu.com/community/SwapFaq" target="_blank">Ubuntu</a>_
11. Configure automatic updates, upgrades, & cleanup.
	- `sudo apt-get install unattended-upgrades`
	- `sudo dpkg-reconfigure -plow unattended-upgrades`
		- Select "Yes" to auto-install upgrades.
	- `sudo nano /etc/apt/apt.conf.d/20auto-upgrades`
		- Add `APT::Periodic::Download-Upgradeable-Packages "1";`
		- Add `APT::Periodic::AutocleanInterval "1";`
	- `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
		- Uncomment `"${distro_id}:${distro_codename}-updates";`
		- Uncomment and modify `Unattended-Upgrade::Automatic-Reboot "true";`        
12. Update kernel. (DO only.)
	- `sudo apt-get install linux-generic-lts-` (Double-tap "Tab")
        - Note the newest alphabetical codename {newestKernelCodename}.
        - `sudo apt-get install linux-generic-lts-{newestKernelCodename}`
    - `ls /boot/`
      - Note the newest version of vmlinuz installed.
    - `sudo poweroff`
    - In DO control panel, navigate to the droplet's settings->kernel.
    - If available/applicable, select and change to the newest version of vmlinuz installed on the droplet.
	- _via <a href="http://askubuntu.com/a/598934" target="_blank">David Foerster</a>_
13. Update all the things and tidy up.
    - `sudo apt-get update`
    - `sudo apt-get upgrade`
    - `sudo apt-get dist-upgrade`
    - `sudo apt-get autoremove`
    - `sudo apt-get autoclean`
14. Snapshot 2
15. Download, compile, and install nginx w/ngx_pagespeed.
	- `sudo add-apt-repository -s -y ppa:nginx/development`
	- `sudo apt-get update`
	- `sudo apt-get -y build-dep nginx`
	- `sudo mkdir -p /opt/nginx`
	- `sudo chown {myUser}:{myUser} /opt/nginx`
	- `cd /opt/nginx`
	- `apt-get source nginx`
	- `cd nginx-{nginxCurVer}/debian/modules/`
	- `wget {npsTarLink}` (Copy link to the newest tar.gz <a href="https://github.com/pagespeed/ngx_pagespeed/releases" target="_blank">here</a>.)
	- `tar -xzvf {npsTarFile}`
	- `rm {npsTarFile}`
	- `cd ngx_pagespeed-{npsCurVer}-beta/`
	- `wget https://dl.google.com/dl/page-speed/psol/{npsCurVer}.tar.gz`
	- `tar -xzvf {npsCurVer}.tar.gz`
	- `rm {npsCurVer}.tar.gz`
	- `sudo nano ../../rules`
		- Under "light" version flags:
            - Add ` \` to the end of the last flag.
            - Add `--with-http_v2_module \`
			- Add `--add-module=$(MODULESDIR)/nginx-cache-purge \`
			- Add `--add-module=$(MODULESDIR)/ngx_pagespeed-{NpsCurVer}-beta`
	- `cd /opt/nginx/nginx-{nginxCurVer}/`
	- `sudo dpkg-buildpackage -b`
	- `cd /opt/nginx/`
	- `sudo dpkg -i nginx_{nginxCurVer}+trusty0_all.deb nginx-common_{nginxCurVer}+trusty0_all.deb nginx-doc_{nginxCurVer}+trusty0_all.deb nginx-light_{nginxCurVer}+trusty0_amd64.deb`
		- If there are dependency errors due to the version of python installed:
        	- `sudo apt-get -f install`
            	- Press "return" to install.
	- `echo "nginx-light hold" | sudo dpkg --set-selections`
    - `sudo service nginx restart`
    - Verify nginx is installed by visiting {myVpsIP} in a browser.
    - `sudo rm -rf /opt/`
    - `sudo rm -rf /var/www/html/`
	- _via <a href="https://blog.rudeotter.com/nginx-modules-pagespeed-ubuntu/" target="_blank">Rude Otter</a>_
16. Snapshot 3
17. Install MariaDB.
	- Follow the 5 commands <a href="https://downloads.mariadb.org/mariadb/repositories/" target="_blank">here</a> based on the setup.
		- Use the DO node that the VPS is hosted on as the mirror in both the 4th box and the 3rd command.
		- Provide {myMariaDBRootPassword}.
	- `mysql_secure_installation`
		- Type "n" for do not change root password.
		- Press "return" repeatedly to accept the rest of the default options.
    - `mysql -u root -p`
        - Provide {myMariaDBRootPassword}.
    - `SET GLOBAL query_cache_size = 16000000;`
    - `exit`
18. Install PHP.
    - `sudo apt-get install python-software-properties`
    - `sudo add-apt-repository ppa:ondrej/php-7.0`
    - `sudo apt-get update`
	- `sudo apt-get install php7.0-fpm php7.0-mysql`
	- `sudo nano /etc/php/7.0/fpm/php.ini`
		- Uncomment and modify `cgi.fix_pathinfo=0`
    - `sudo service php7.0-fpm restart`
	- _via <a href="https://bjornjohansen.no/upgrade-to-php7" target="_blank">Bjørn Johansen</a>_
19. Install HHVM.
	- Follow the commands for the linux distro <a href="http://docs.hhvm.com/hhvm/installation/introduction#prebuilt-packages" target="_blank">here</a>.
	- `sudo /usr/share/hhvm/install_fastcgi.sh`
	- `sudo update-rc.d hhvm defaults`
	- `sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60`
    - `sudo nano /etc/hhvm/server.ini`
    	- Comment out `hhvm.server.port = 9000`
        - Add `hhvm.server.file_socket=/var/run/hhvm/hhvm.sock`
	- `sudo service hhvm restart`
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
20. Install monit to automatically restart HHVM on crash.
    - `sudo apt-get install monit`
    - `sudo nano /etc/monit/conf.d/hhvm`

        ```
        check process hhvm with pidfile /var/run/hhvm/pid
          group hhvm
          start program = "/usr/sbin/service hhvm start" with timeout 60 seconds
          stop program = "/usr/sbin/service hhvm stop"
          if failed unixsocket /var/run/hhvm/hhvm.sock then restart
          if mem > 400.0 MB for 1 cycles then restart
          if 5 restarts with 5 cycles then timeout
        ```

    - `sudo nano /etc/monit/monitrc`
        - Uncomment and modify

            ```
            set mailserver {mySmtpMailServer} port {mySmtpPort}
            username "{mySmtpEmailAddress}" password "{mySmtpPassword}"
            using tlsv1
            ```

        - Modify `set alert {mySmtpEmailAddress} with reminder on 15 cycles`
        - Uncomment

            ```
            set httpd port 2812 and
            use address localhost
            allow localhost
            ```

    - `sudo service monit restart`
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
21. Snapshot 4
22. Create a database for WordPress.
	- `mysql -u root -p`
    	- Provide {myMariaDBRootPassword}.
	- `CREATE DATABASE {myWPDB};`
    - `CREATE USER {myWPDBUser}@localhost IDENTIFIED BY '{myWPDBPassword}';`
    - `GRANT ALL PRIVILEGES ON {myWPDB}.* TO {myWPDBUser}@localhost;`
    - `FLUSH PRIVILEGES;`
    - `exit`
    - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, and {myWPDBPassword}.
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04" target="_blank">DigitalOcean</a>_
23. Download and install WordPress.
	- `sudo apt-get update`
	- `sudo apt-get install php7.0-gd`
    - `wget http://wordpress.org/latest.tar.gz`
    - `tar -xzvf latest.tar.gz`
    - `rm latest.tar.gz`
    - `cd ~/wordpress`
    - `cp wp-config-sample.php wp-config.php`
    - `rm wp-config-sample.php`
    - `sudo nano wp-config.php`
    	- Modify `define('DB_NAME', '{myWPDB}');`
        - Modify `define('DB_USER', '{myWPDBUser}');`
        - Modify `define('DB_PASSWORD', '{myWPDBPassword}');`
        - Replace `{myWPSecurityKeys}` (<a href="https://api.wordpress.org/secret-key/1.1/salt/" target="_blank">Generate {myWPSecurityKeys}</a>)
        - Modify `$table_prefix  = '{myRandomPrefix}_';` (<a href="https://www.wolframalpha.com/input/?i=password+generator&a=*MC.~-_*Formula.dflt-&a=FSelect_**PasswordSingleBasic-.dflt-&f3=16+characters&f=PasswordSingleBasic.pl_16+characters" target="_blank">Generate {myRandomPrefix}</a>)
        - Add `define( 'WP_AUTO_UPDATE_CORE', true );`
	- `mkdir wp-content/uploads`
	- `sudo mkdir -p /var/www/{myWPSiteName}`
    - `sudo rsync -avP ~/wordpress/ /var/www/{myWPSiteName}/`
    - `sudo chown -R www-data:www-data /var/www/{myWPSiteName}`
    - `rm -rf ~/wordpress/`
    - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, {myWPDBPassword}, {myWPSecurityKeys}, and {myRandomPrefix}.
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04" target="_blank">DigitalOcean</a>_
24. Snapshot 5
25. Configure nginx.
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/nginx.conf -O /etc/nginx/nginx.conf`
    - `sudo mkdir /etc/nginx/global`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/common.conf -O /etc/nginx/global/common.conf`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/wordpress.conf -O /etc/nginx/global/wordpress.conf`
    - If multisite, `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/multisite.conf -O /etc/nginx/global/multisite.conf`
    - `sudo rm /etc/nginx/sites-available/default`
    - `sudo rm /etc/nginx/sites-enabled/default`
    - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/sites-available/example.com -O /etc/nginx/sites-available/example.com`
    - `sudo mv /etc/nginx/sites-available/example.com /etc/nginx/sites-available/{myWPSiteName}`
    - `sudo nano /etc/nginx/sites-available/{myWPSiteName}`
        - Modify `root /var/www/{myWPSiteName};`
        - Modify `pagespeed LoadFromFile "https://{myWPSiteUrl}/" "/var/www/{myWPSiteName}/";`
        - Replace `example.com` with `{myWPSiteUrl}`
    - `sudo ln -s /etc/nginx/sites-available/{myWPSiteName} /etc/nginx/sites-enabled/{myWPSiteName}`
    - Repeat the last four bullets for each WordPress site to be installed with new values for {myWPSiteName} and {myWPSiteUrl}.
    - _via <a href="https://www.digitalocean.com/community/tutorials/how-to-configure-single-and-multiple-wordpress-site-settings-with-nginx" target="_blank">DigitalOcean</a>, <a href="https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration" target="_blank">DigitalOcean</a>_
26. Configure TLS encryption.
    - `sudo mkdir /etc/nginx/cert`
    - `sudo chmod 710 /etc/nginx/cert`
    - `sudo openssl dhparam 2048 -out /etc/nginx/cert/dhparam.pem`
    - `sudo chmod 600 /etc/nginx/cert/dhparam.pem`
    - `sudo apt-get install git`
    - `git clone https://github.com/letsencrypt/letsencrypt`
    - `cd letsencrypt`
    - `sudo service nginx stop`
    - `./letsencrypt-auto certonly`
    	- This assumes DNS records have already been configured to point {myWPSiteUrl} to {myVpsIp}.
        - Provide `{myWPSiteUrl},www.{myWPSiteUrl}` as domains for the certificates.
    - `sudo service nginx start`
    - Verify nginx and TLS is configured by visiting {myWPSiteUrl} in a browser.
    - Complete the 1-page WordPress setup so that a random passerby might not botch your new site.
    - **TODO**: Document how to create certificates for additional domains using Let's Encrypt.
    - **TODO**: Configure cron to auto-renew TLS certificate every 60 days.
    - _via <a href="https://oct.im/install-lets-encrypt-ca-on-apache-and-nginx.html" target="_blank">oct.im</a>_
27. Snapshot 6
28. Install and configure redis.
	- `sudo apt-get install redis-server`
	- `sudo apt-get install php-redis`
    - `sudo nano /var/www/{myWPSiteName}/wp-config.php`
        - Add
        
            ```
            define( 'WP_CACHE_KEY_SALT', '{myWPSiteName}_' );
            $redis_server = array( 'host' => '127.0.0.1', 'port' => 6379, );
            ```

    - Login to your site at {myWPSiteUrl}/wp-login.php.
    - Search the plugin repository for "wp-redis" and install it.
        - The plugin does not ever need to be activated, though.
    - `sudo ln -s /var/www/{myWPSiteName}/wp-content/plugins/wp-redis/object-cache.php /var/www/{myWPSiteName}/wp-content`
    - Verify redis is working by `redis-cli monitor` and refresh the webpage.
    - _via <a href="https://codeable.io/community/speed-up-wp-admin-redis-hhvm/" target="_blank">Codeable</a>_
29. Configure FastCGI microcaching.
    - Search the plugin repository for "nginx-helper" and install it.
    - Activate "nginx-helper"
    - In Settings->nginx-helper,
        - Enable Purge
        - Select nginx Fastcgi cache
        - Customize when Fastcgi cache should be purged
    - **TODO**: Store FastCGI cache in tmpfs.
    - _via <a href="https://easyengine.io/wordpress-nginx/tutorials/single-site/fastcgi-cache-with-purging/" target="_blank">EasyEngine</a>_
30. Configure ngx_pagespeed.
    - `sudo mkdir -p /var/ngx_pagespeed_cache`
    - `sudo chown www-data:www-data /var/ngx_pagespeed_cache`
    - `sudo nano /etc/fstab`
        - Add `tmpfs /var/ngx_pagespeed_cache tmpfs size=100m,mode=0775,uid=www-data,gid=www-data 0 0`
    - `sudo mount -t tmpfs -o size=100M,mode=0755 tmpfs /var/ngx_pagespeed_cache`
    - `sudo nano /etc/nginx/nginx.conf`
        - Modify `pagespeed off;`
    - `sudo service nginx restart`
    - _via <a href="https://developers.google.com/speed/pagespeed/module/" target="_blank">Google PageSpeed Module</a>_
31. **TODO**: Optimize swap, nginx, MariaDB, HHVM, php7.0-fpm, Redis, ngx_pagespeed, etc.

## Recommended Ongoing Maintenance
- Whenever nginx or ngx_pagespeed have a new release, repeat step 15. nginx will first need to be uninstalled (`sudo apt-get remove nginx`) before installing the newly compiled version.
- If the VPS is ever resized, the swap file should be resized.
- Step 12 should be repeated whenever a new version of the kernel is installed.
- MariaDB should be tuned on occasion for optimum performance.
- Renew TLS certificate every 60 days via `./letsencrypt-auto certonly`.
