upstream php {
  server 127.0.0.1:9000;
  server unix:/var/run/php5-fpm.sock;
}

server {
  listen [::]:80;
  listen 80;
  
  server_name example.com;
  
  return 301 https://example.com$request_uri;
}

server {
  listen [::]:443 ssl;
  listen 443 ssl;
  server_name example.com;
  root /var/www/{myWPSiteName};
  
  ssl_certificate      /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key  /etc/ssl/private/ssl-cert-snakeoil.key;
    
  index index.php;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location = /favicon.ico {
    log_not_found off;
    access_log off;
  }

  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }

  rewrite /wp-admin$ $scheme://$host$uri/ permanent;

  location ~ \.php$ {
    include fastcgi.conf;
    fastcgi_intercept_errors on;
    fastcgi_pass php;
  }

}
