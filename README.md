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
| Database | MariaDB | |
| Object Cache Store | Redis | |
| PHP Compiler | HHVM | |
| Web Server | NGINX | w/microcaching |
| Connection | Let's Encrypt TLS<br>HTTP/2<br>ipv4 / ipv6 | |

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
This build guide is constructed from a compilation of sources from all over the web. Inline "via"s give credit to some of these authors, but apologies go out to any blogs that were forgotten. A special shout goes out to [Mark Jaquith](http://wordpress.tv/2014/10/16/mark-jaquith-next-generation-wordpress-hosting-stack/) and [Carl Alexander](http://wordpress.tv/2016/05/03/carl-alexander-a-look-at-the-modern-wordpress-server-stack/) whose talks played a fundamental role in this architecture.

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
  - Don’t close the Terminal window, yet. In another local Terminal window:
    - `sudo nano ~/.ssh/config`

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
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers), [Ubuntu](https://help.ubuntu.com/community/SwapFaq)*
12. Configure automatic updates, upgrades, and cleanup.
  - `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
    - Uncomment `"${distro_id}:${distro_codename}-updates";`
  - `sudo nano /etc/apt/apt.conf.d/10periodic`
    - Modify `APT::Periodic::Download-Upgradeable-Packages "1";`
    - Modify `APT::Periodic::AutocleanInterval "7";`
  - *via [Ubuntu](https://help.ubuntu.com/lts/serverguide/automatic-updates.html)*
13. Snapshot 2
14. Install NGINX.
  - `sudo apt-get install nginx`
15. Install MariaDB.
  - Follow the 5 commands [here](https://downloads.mariadb.org/mariadb/repositories/) based on the setup.
    - Use the DO node that the VPS is hosted on as the mirror in both the 4th box and the 3rd command.
    - Provide {myMariaDBRootPassword}.
  - `mysql_secure_installation`
    - Provide {myMariaDBRootPassword}.
    - Type "n" for do not change root password.
    - Press "return" repeatedly to accept the rest of the default options.
16. Install HHVM.
  - Follow the commands for the linux distro [here](http://docs.hhvm.com/hhvm/installation/introduction#prebuilt-packages).
  - `sudo /usr/share/hhvm/install_fastcgi.sh`
  - `sudo update-rc.d hhvm defaults`
  - `sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60`
  - `sudo nano /etc/hhvm/server.ini`
    - Replace `hhvm.server.port = 9000` with `hhvm.server.file_socket=/var/run/hhvm/hhvm.sock`
  - `sudo service hhvm restart`
  - *via [Codeable](https://codeable.io/community/speed-up-wp-admin-redis-hhvm/)*
17. Snapshot 3
18. Create a database for WordPress.
  - `mysql -u root -p`
    - Provide {myMariaDBRootPassword}.
    - `CREATE DATABASE {myWPDB};`
    - `CREATE USER {myWPDBUser}@localhost IDENTIFIED BY '{myWPDBPassword}';`
    - `GRANT ALL PRIVILEGES ON {myWPDB}.* TO {myWPDBUser}@localhost;`
    - `FLUSH PRIVILEGES;`
    - `exit`
  - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, and {myWPDBPassword}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04)*
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
    - Modify `$table_prefix  = '{myRandomPrefix}_';` ([Generate {myRandomPrefix}](https://www.wolframalpha.com/input/?i=password+generator&a=*MC.~-_*Formula.dflt-&a=FSelect_**PasswordSingleBasic-.dflt-&f3=16+characters&f=PasswordSingleBasic.pl_16+characters))
    - Add `define( 'WP_AUTO_UPDATE_CORE', true );`
  - `mkdir wp-content/uploads`
  - `sudo mkdir -p /var/www/{myWPSiteName}`
  - `sudo rsync -avP ~/wordpress/ /var/www/{myWPSiteName}/`
  - `sudo chown -R www-data:www-data /var/www/{myWPSiteName}`
  - `rm -rf ~/wordpress/`
  - Repeat this step for each WordPress site to be installed with new values for {myWPDB}, {myWPDBUser}, {myWPDBPassword}, {myWPSecurityKeys}, and {myRandomPrefix}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-ubuntu-14-04)*
20. Snapshot 4
21. Configure nginx.
  - `sudo ufw allow Nginx Full`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/nginx.conf -O /etc/nginx/nginx.conf`
  - `sudo mkdir /etc/nginx/global`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/common.conf -O /etc/nginx/global/common.conf`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/global/wordpress.conf -O /etc/nginx/global/wordpress.conf`
  - `sudo rm /etc/nginx/sites-available/default`
  - `sudo rm /etc/nginx/sites-enabled/default`
  - `sudo wget https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/sites-available/example.com -O /etc/nginx/sites-available/example.com`
  - `sudo mv /etc/nginx/sites-available/example.com /etc/nginx/sites-available/{myWPSiteName}`
  - `sudo nano /etc/nginx/sites-available/{myWPSiteName}`
    - Modify `root /var/www/{myWPSiteName};`
    - Replace `example.com` with `{myWPSiteUrl}`
  - `sudo ln -s /etc/nginx/sites-available/{myWPSiteName} /etc/nginx/sites-enabled/{myWPSiteName}`
  - Repeat the last four bullets for each WordPress site to be installed with new values for {myWPSiteName} and {myWPSiteUrl}.
  - *via [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-configure-single-and-multiple-wordpress-site-settings-with-nginx), [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration)*
22. Configure TLS encryption.
  - `sudo mkdir /etc/nginx/cert`
  - `sudo chmod 710 /etc/nginx/cert`
  - `sudo openssl dhparam 2048 -out /etc/nginx/cert/dhparam.pem`
  - `sudo chmod 600 /etc/nginx/cert/dhparam.pem`
  - `sudo apt-get install git`
  - `sudo apt-get install python-pip`
  - `sudo pip install pyopenssl ndg-httpsclient pyasn1`
  - `sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt`
  - `cd /opt/letsencrypt`
  - `sudo service nginx stop`
  - `./letsencrypt-auto certonly --standalone --rsa-key-size 4096 --agree-tos --email {myEmailAddress} -d {myWPSiteUrl} -d www.{myWPSiteUrl}`
    - This assumes DNS records have already been configured to point {myWPSiteUrl} to {myVpsIp}.
    - If your domain is routing through a DNS service like CloudFlare, you will need to temporarily disable it until you have obtained the certificate.
    - Repeat this command for each WordPress site to be installed.
  - `sudo service nginx start`
  - Verify NGINX and TLS is configured by visiting {myWPSiteUrl} in a browser.
  - Complete the 1-page WordPress setup so that a random passerby might not botch your new site.
  - `sudo cp /opt/letsencrypt/examples/cli.ini /usr/local/etc/le-renew-webroot-{myWPSiteName}.ini`
  - `sudo nano /usr/local/etc/le-renew-webroot-{myWPSiteName}.ini`
    - Uncomment and modify `email` and `domains` directives
      - Note: The order of the domains should match the order of the initial certificate creation command above.
    - Uncomment `webroot-path` directive
  - `sudo curl -L -o /usr/local/sbin/le-renew-webroot-{myWPSiteName} https://raw.githubusercontent.com/collinbarrett/wp-vps-build-guide/master/le-renew-webroot`
  - `sudo chmod +x /usr/local/sbin/le-renew-webroot-{myWPSiteName}`
  - `sudo nano /usr/local/sbin/le-renew-webroot-{myWPSiteName}`
    - Modify `config_file="/usr/local/etc/le-renew-webroot-{myWPSiteName}.ini"`
  - Verify script works by executing `sudo le-renew-webroot-{myWPSiteName}`
  - `sudo crontab -e`
    - Add `0 8 * * * /usr/local/sbin/le-renew-webroot-{myWPSiteName} >> /var/log/le-renewal.log`
  - Repeat the previous 5 commands for each WordPress site to be installed.
  - `sudo reboot now`
    - Required to purge cache after completing WordPress setup.
  - *via [oct.im](https://oct.im/install-lets-encrypt-ca-on-apache-and-nginx.html), [DigitalOcean](www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04)*
23. Snapshot 5
24. Install and configure redis.
  - `sudo apt-get install redis-server`
  - `sudo nano /var/www/{myWPSiteName}/wp-config.php`

    ```
    define( 'WP_CACHE_KEY_SALT', '{myWPSiteName}_' );
    $redis_server = array( 'host' => '127.0.0.1', 'port' => 6379, );
    ```

  - Login to your site at {myWPSiteUrl}/wp-login.php.
  - Search the plugin repository for "wp-redis" and install it.
    - The plugin does not ever need to be activated, though.
  - `sudo ln -s /var/www/{myWPSiteName}/wp-content/plugins/wp-redis/object-cache.php /var/www/{myWPSiteName}/wp-content`
  - Verify redis is working by `redis-cli monitor` and refresh the webpage.
  - *via [Codeable](https://codeable.io/community/speed-up-wp-admin-redis-hhvm/)*
25. Configure FastCGI microcaching.
  - Search the plugin repository for "nginx-helper" and install it.
  - Activate "nginx-helper"
  - In Settings->nginx-helper,
    - Select "Enable Purge"
    - Select "nginx Fastcgi cache"
    - Select "Delete local server cache files"
    - Customize when the FastCGI cache should be purged
  - *via [EasyEngine](https://easyengine.io/wordpress-nginx/tutorials/single-site/fastcgi-cache-with-purging/)*
26. Snapshot 6

## Ongoing Maintenance
- If the VPS is ever resized, the swap file size should be re-evaluated.
- MariaDB should be tuned on occasion for optimum performance.
- Renew TLS certificate every 60 days via `./letsencrypt-auto certonly`.
