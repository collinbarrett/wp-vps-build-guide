server {
    server_name www.example.com;
    rewrite ^/(.*)$ http://example.com/$1 permanent;
}

server {
    server_name example.com;
    root /var/www/example.com;
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;
    include global/common.conf;
    include global/wordpress.conf;
}