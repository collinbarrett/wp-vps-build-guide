server {
    server_name www.example.com;
    rewrite ^/(.*)$ https://example.com/$1 permanent;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name example.com;
    root /var/www/example;
    include global/common.conf;
    include global/wordpress.conf;
    
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    
    location /.well-known {
        allow all;
    }
}