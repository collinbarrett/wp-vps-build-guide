server {
    server_name www.example.com;
    rewrite ^/(.*)$ http://example.com/$1 permanent;
}

server {
    listen 80;
    # listen 443 default ssl http2;
    # listen [::]:443 default ssl http2 ipv6only=on;

    server_name example.com;
    root /var/www/example.com;
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;
    include global/common.conf;
    include global/wordpress.conf;
    
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
}
