# wp-vps-build-guide
A verbose build guide for a modern, high-performance production WordPress VPS.

[Introductory Blog Post](https://collinmbarrett.com/wp-vps-build-guide/ "WordPress VPS: DIY Build Guide for Fast and Cheap Hosting - collinmbarrett.com")

## Intro
This project aims to provide a straightforward, albeit lengthy and all-inclusive, build guide for a low-budget, high-performance WordPress hosting solution. For as little as $5/mo., one can develop a cutting edge hosting stack for his or her projects. The instructions are verbose so that developers with little server administration experience can track.

### The Stack

| Component | Solution | Notes |
|---|---|---|
| Development Client | macOS | |
| Production Host | DigitalOcean | |
| Server | Ubuntu LTS x64 |  |
| WordPress Management Tools | WP-CLI |  |
| Database | MariaDB | |
| Object Cache Store | Redis | |
| PHP Compiler | HHVM | |
| Web Server | NGINX | w/FastCGI Caching<br>(Persistent In-Memory) |
| Connection | Modern TLS Ciphers<br>HTTP/2<br>ipv4/ipv6 | |

### Scope
This stack is designed to host one or multiple WordPress sites with light to medium loads. It will scale well, but it is not designed for an ultra-heavy use case that requires load balancing across multiple servers, etc. Server configurations are not one-size-fits-all, for sure, but hopefully this guide serves as a "good-enough-for-most" solution. While configuration recommendations provided are a good starting point, it is no substitution for ongoing optimization. Both speed and security have been key values during the development of this guide. The instructions to follow are scoped to only cover a single self-contained VPS. No load-balancing or CDN configuration is described, while these are highly recommended.

### General Notes
- Items in curly brackets {} should be treated as variables and replaced with custom info.
- Recommended Snapshot points are annotated throughout, but feel free to take these more or less frequently.

### Assumptions
- The developer has basic Linux terminal skills.
- The developer has access to a VPS host. DigitalOcean (DO) is used for the purposes of this guide, but competitors such as Linode work just fine with minor adaptations.
- The developer has a ssh key already created. The public key is stored with the host and the private .pem stored locally at {myPK}.

### Support
The best way to support this project is to submit issues and pull requests to assist in keeping the guide up-to-date. Clicking through the maintainer's [DigitalOcean affiliate link](http://brrt.co/CBDigitalOcean) when signing up is helpful as well, but by no means expected.

#### To amateurs at WordPress Operations...
Feel free to use this guide to turbocharge projects! Please submit issues or pull requests for any problems discovered.

#### To experts at WordPress Operations...
Please provide feedback. This guide should continue to receive ongoing optimizations and updates. In its current state, it will lead to a server that is higher-performing than most, but it is not perfect and the technologies powering it are constantly changing. Issues and pull requests are welcome.

### Sources
This build guide is constructed from a compilation of sources from all over the web. Inline "via"s give credit to some of these authors, but apologies go out to any blogs that were forgotten. A special recognition goes out to [Mark Jaquith](http://wordpress.tv/2014/10/16/mark-jaquith-next-generation-wordpress-hosting-stack/) and [Carl Alexander](http://wordpress.tv/2016/05/03/carl-alexander-a-look-at-the-modern-wordpress-server-stack/) whose talks played fundamental roles in this architecture.

## Roadmap / To-Do

### Near-Term

- Redis Persistence
- NGINX FastCGI Cache Tuning
- Move NGINX FastCGI Cache to tmpfs w/Persistence
- MariaDB Tuning
- Verify Ubuntu Automatic Upgrades
- Verify WordPress Ownership and Permissions
- SSL Certificate Installation
- SSH Key Installation
- Automated _Scheduled_ Backups

### Moonshots / Long-Term

- Automated _Realtime_ Backups
- Automated Build Script
- Dockerize
- Clusterize

## Build Guide
1. Create a new VPS running the latest Ubuntu LTS x64 in the DO control panel.
  - Enable backups.
  - Enable IPv6.
  - Add your SSH key.
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
    - Provide {myUserPassword} twice when prompted.
    - Press "return" repeatedly to accept the rest of the default options.
  - `usermod -aG sudo {myUser}`
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04)*
5. Copy the ssh key to the new user and configure ssh.
  - `mkdir /home/{myUser}/.ssh`
  - `cp ~/.ssh/authorized_keys /home/{myUser}/.ssh/`
  - `chown -R {myUser}:{myUser} /home/{myUser}/.ssh`
  - `chmod 700 /home/{myUser}/.ssh`
  - `chmod 600 /home/{myUser}/.ssh/authorized_keys`
  - `nano /etc/ssh/sshd_config`
    - Modify `PermitRootLogin no`
    - Uncomment and modify `PasswordAuthentication no`
  - `service ssh restart`
  - Do not close the Terminal window yet. In a new Terminal window, `sudo nano ~/.ssh/config`

      ```
      Host {myVpsName}
        HostName {myVpsIP}
        Port 22
        User {myUser}
        IdentityFile {myPK}
      ```

  - Test ssh into the VPS as {myUser} before closing the root Terminal window.
    - `ssh {myVPSName}`
  - Type `exit` in the root Terminal window and close it.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04)*
6. Ensure all of the latest updates are installed.
  - `sudo apt-get update`
    - Provide {myUserPassword} when prompted.
  - `sudo apt-get upgrade`
  - `sudo apt-get dist-upgrade`
7. Snapshot 1
  - `sudo poweroff`
  - Create a Snapshot in the DO control panel.
8. Configure a basic firewall with ufw.
  - `sudo ufw allow OpenSSH`  
  - `sudo ufw enable`
    - Type "y" to proceed with the operation.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04)*
9. Install fail2ban to protect SSH.
  - `sudo apt-get install fail2ban`
  - `sudo service fail2ban restart`
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04)*
10. Update the timezone and configure ntp sync.
  - `sudo dpkg-reconfigure tzdata`
    - Select the local timezone.
  - `sudo apt-get update`
  - `sudo apt-get install ntp`
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers#configure-timezones-and-network-time-protocol-synchronization)*
11. Enable a swap file.
  - `sudo fallocate -l {swapSizeInGb}G /swapfile`
    - For guidance on determining {swapSizeInGb}, see [here](https://help.ubuntu.com/community/SwapFaq#How_much_swap_do_I_need.3F).
  - `sudo chmod 600 /swapfile`
  - `sudo mkswap /swapfile`
  - `sudo swapon /swapfile`
  - `sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'`
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)*
12. Configure automatic updates, upgrades, and cleanup.
  - `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
    - Uncomment `"${distro_id}:${distro_codename}-updates";`
  - `sudo nano /etc/apt/apt.conf.d/10periodic`
    - Modify `APT::Periodic::Download-Upgradeable-Packages "1";`
    - Modify `APT::Periodic::AutocleanInterval "7";`
  - *via [Ubuntu](https://help.ubuntu.com/lts/serverguide/automatic-updates.html)*
13. Snapshot 2
14. Install NGINX with ngx_cache_purge.
  - `sudo apt-get install nginx`
15. Install MariaDB.
  - Follow the 5 commands [here](https://downloads.mariadb.org/mariadb/repositories/) based on the setup.
    - Use the DO node that the VPS is hosted on as the mirror in both the 4th box and the 3rd command.
    - Provide {myMariaDBRootPassword} twice when prompted.
  - `mysql_secure_installation`
    - Provide {myMariaDBRootPassword}.
    - Type `n` for do not change root password.
    - Press "return" repeatedly to accept the rest of the default options.
16. Install HHVM.
  - `sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449`
  - `sudo add-apt-repository "deb http://dl.hhvm.com/ubuntu $(lsb_release -sc) main"`
  - `sudo apt-get update`
  - `sudo apt-get install hhvm`
  - `sudo update-rc.d hhvm defaults`
  - `sudo /usr/share/hhvm/install_fastcgi.sh`
  - `sudo nano /etc/hhvm/server.ini`
    - Replace `hhvm.server.port = 9000` with `hhvm.server.file_socket=/var/run/hhvm/hhvm.sock`
  - `sudo service hhvm restart`
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-hhvm-with-nginx-on-ubuntu-14-04)*
17. Snapshot 3
18. Create a database for WordPress.
  - `mysql -u root -p`
    - Provide {myMariaDBRootPassword}.
    - `CREATE DATABASE {myWPDB} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;`
    - `GRANT ALL ON {myWPDB}.* TO '{myWPDBUser}'@'localhost' IDENTIFIED BY '{myWPDBPassword}';`
    - `FLUSH PRIVILEGES;`
    - `exit`
  - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, and {myWPDBPassword}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-lemp-on-ubuntu-16-04)*
19. Download and install WordPress.
  - `wget http://wordpress.org/latest.tar.gz`
  - `tar -xzvf latest.tar.gz`
  - `rm latest.tar.gz`
  - `cd ~/wordpress`
  - `cp wp-config-sample.php wp-config.php`
  - `sudo nano wp-config.php`
    - Modify `define('DB_NAME', '{myWPDB}');`
    - Modify `define('DB_USER', '{myWPDBUser}');`
    - Modify `define('DB_PASSWORD', '{myWPDBPassword}');`
    - Replace `{myWPSecurityKeys}` [Generate {myWPSecurityKeys}](https://api.wordpress.org/secret-key/1.1/salt/)
    - Modify `$table_prefix  = '{myRandomPrefix}_';` ([Generate {myRandomPrefix}](https://www.random.org/strings/?num=1&len=8&loweralpha=on&unique=on&format=html&rnd=new))
    - Add `define( 'WP_AUTO_UPDATE_CORE', true );`
  - `mkdir wp-content/uploads`
  - `sudo mkdir -p /var/www/{myWPSiteName}`
  - `sudo rsync -avP ~/wordpress/ /var/www/{myWPSiteName}/`
  - `rm -rf ~/wordpress/`
  - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, {myWPDBPassword}, {myWPSecurityKeys}, and {myRandomPrefix}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-lemp-on-ubuntu-16-04)*
20. Configure permissions and ownership. (WARNING: still under review, however these should be appropriate)
  - `sudo chown root:root /var/www/{myWPSiteName}/`
  - `sudo chown -R {myUser}:{myUser} /var/www/{myWPSiteName}/*`
  - `sudo chown {myUser}:www-data /var/www/{myWPSiteName}/wp-config.php`
  - `sudo find /var/www/{myWPSiteName}/ -type d -exec chmod 755 {} \;`
  - `sudo find /var/www/{myWPSiteName}/ -type f -exec chmod 644 {} \;`
  - `sudo chmod 400 /var/www/{myWPSiteName}/wp-config.php`
  - High Security Variant (does not allow plugins to be installed via Dashboard, recommended for use in conjunction with wp-cli)
    - `sudo chown -R www-data:www-data /var/www/{myWPSiteName}/wp-content/uploads/`
  - Medium Security Variant
    - `sudo chown -R www-data:www-data /var/www/{myWPSiteName}/wp-content/`
  - - *via [StackOverflow](https://stackoverflow.com/questions/18352682/correct-file-permissions-for-wordpress)*
21. Snapshot 4
22. Configure FastCGI Cache RAM disk.
  - `sudo mkdir /mnt/ramdisk`
  - `sudo nano /etc/fstab`
    - Add `tmpfs /mnt/ramdisk tmpfs defaults,size=32M 0 0`
  - `sudo mount /mnt/ramdisk`
  - `sudo mkdir /var/ramdisk-backup`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/ramdisk -O /etc/init.d/ramdisk`
  - `sudo chmod +x /etc/init.d/ramdisk`
  - `sudo /etc/init.d/ramdisk sync`
  - `sudo crontab -e`
    - Add `@reboot /etc/init.d/ramdisk start >> /dev/null 2>&1`
    - Add `2 * * * * /etc/init.d/ramdisk sync >> /dev/null 2>&1`
  - *via [Observium](https://www.observium.org/docs/persistent_ramdisk/)*
23. Configure nginx.
  - `sudo ufw allow 'Nginx Full'`
  - `sudo wget https://raw.githubusercontent.com/h5bp/server-configs-nginx/master/mime.types -O /etc/nginx/mime.types`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/nginx.conf -O /etc/nginx/nginx.conf`
  - `sudo mkdir /etc/nginx/global`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/common.conf -O /etc/nginx/global/common.conf`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/wordpress.conf -O /etc/nginx/global/wordpress.conf`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/hackrepair.conf -O /etc/nginx/global/hackrepair.conf`
  - `sudo rm /etc/nginx/sites-available/default`
  - `sudo rm /etc/nginx/sites-enabled/default`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/sites-available/example -O /etc/nginx/sites-available/example`
  - `sudo mv /etc/nginx/sites-available/example /etc/nginx/sites-available/{myWPSiteName}`
  - `sudo nano /etc/nginx/sites-available/{myWPSiteName}`
    - Modify `root /var/www/{myWPSiteName};`
    - Replace `example.com` with `{myWPSiteUrl}`
    - If site should not be the default for the server, toggle listen directives so the ones without `default_server` are active.
  - `sudo ln -s /etc/nginx/sites-available/{myWPSiteName} /etc/nginx/sites-enabled/{myWPSiteName}`
  - Repeat the last four top-level bullets for each WordPress site to be installed with new values for {myWPSiteName} and {myWPSiteUrl}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-configure-single-and-multiple-wordpress-site-settings-with-nginx), [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration)*
24. Configure TLS encryption.
  - `sudo mkdir /etc/nginx/cert`
  - `sudo chmod 700 /etc/nginx/cert`
  - `sudo openssl dhparam 2048 -out /etc/nginx/cert/dhparam.pem`
  - `sudo chmod 600 /etc/nginx/cert/dhparam.pem`
  - Install certificate(s) and key(s) to `/etc/nginx/cert/`.
    - Outside the scope of this guide.
    - Free Options:
      - [Let's Encrypt](https://letsencrypt.org/)
      - [CloudFlare Origin CA](https://blog.cloudflare.com/cloudflare-ca-encryption-origin/)
      - [StartSSL](https://www.startssl.com/Support?v=1)
25. Snapshot 5
26. Install and configure WP-CLI to auto-update WordPress.
  - `curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar`
  - `chmod +x wp-cli.phar`
  - `sudo mv wp-cli.phar /usr/local/bin/wp`
  - `sudo crontab -e`
    - Add `0 1 * * * /usr/local/bin/wp cli update --yes --allow-root`
  - `crontab -e`
    - Add `0 2 * * * cd /var/www/{myWPSiteName}/ && /usr/local/bin/wp core update --quiet && /usr/local/bin/wp core update-db --quiet && /usr/local/bin/wp plugin update --all --quiet && /usr/local/bin/wp db optimize`
  - *via [WP-CLI](http://wp-cli.org/docs/installing/)*
27. Install and configure Redis.
  - `sudo apt-get install redis-server`
  - `sudo nano /var/www/{myWPSiteName}/wp-config.php`

    ```
    define( 'WP_CACHE_KEY_SALT', '{myWPSiteName}_' );
    $redis_server = array( 'host' => '127.0.0.1', 'port' => 6379, );
    ```

  - `cd /var/www/{myWPSiteName}/`
  - `wp plugin install wp-redis`
  - `sudo ln -s /var/www/{myWPSiteName}/wp-content/plugins/wp-redis/object-cache.php /var/www/{myWPSiteName}/wp-content`
  - Verify Redis is working by `redis-cli monitor` and watching Terminal as you load {myWPSiteUrl} in a browser.
  - Repeat all but the first bullet for each WordPress site to be installed.
  - *via [Codeable](https://codeable.io/community/speed-up-wp-admin-redis-hhvm/)*
28. Install and configure NGINX Helper.
  - `cd /var/www/{myWPSiteName}/`
  - `sudo nano wp-config.php`
    - Add `define('RT_WP_NGINX_HELPER_CACHE_PATH','/etc/nginx/nginx-cache');`
  - `wp plugin install nginx-helper --activate`
  - Log into WordPress and navigate to "Settings -> Nginx Helper".
  - Configure settings as follows. Some settings do not appear until after you click "Save All Changes" the first time.
    - Check `Enable Purge`
    - Check `nginx Fastcgi cache`
    - Check `Delete local server cache files`
    - Check all `Purging Conditions`
  - Repeat all for each WordPress site to be installed.
29. Snapshot 6

## Ongoing Maintenance
- If the VPS is ever resized, the swap file size should be re-evaluated.
- The size of `/mnt/ramdisk` should be tuned on occasion.
- MariaDB should be tuned on occasion.
