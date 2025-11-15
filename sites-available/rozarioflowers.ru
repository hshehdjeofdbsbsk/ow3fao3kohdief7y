# sudo nginx -t && sudo nginx -s reload && sudo systemctl status nginx --no-pager -l
# passenger-config restart-app /srv/rozarioflowers.ru && passenger-status --verbose # passenger-config restart-app <path/to/app>
# https://github.com/openresty/headers-more-nginx-module?tab=readme-ov-file#directives
# https://www.phusionpassenger.com/library/config/nginx/reference/

# sudo tail -n 100 -f /var/log/nginx/passenger.log

server { # HTTP gag
  listen 80;
  # listen [::]:80;
  server_name rozarioflowers.ru *.rozarioflowers.ru rozariofl.ru *.rozariofl.ru; # Для охвата 4-го, 5-го, ..., N-го уровней используйте  `~^([^.]+\.){2,}example\.ru$`
  location = /robots.txt { # Preventively.
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /\nHost: $host\n";
  }
  # location = /.well-known/acme-challenge {
  #   root /srv/rozarioflowers.ru/public/.well-known;
  #   try_files /acme-challenge =404;
  # }
  location / {
    return 301 https://$host$request_uri; # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
  }
  error_log off; access_log off;
}

server { # Redirect from rozariofl.ru to rozarioflowers.ru
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/cert/WC_rozariofl_ru.full.crt;
  ssl_certificate_key /etc/letsencrypt/cert/WC_rozariofl_ru.key;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  server_name rozariofl.ru;
  return 301 $scheme://rozarioflowers.ru$request_uri;
  error_log off; access_log off;
}

server { # Redirect from *.rozariofl.ru to *.rozarioflowers.ru
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/cert/WC_rozariofl_ru.full.crt;
  ssl_certificate_key /etc/letsencrypt/cert/WC_rozariofl_ru.key;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  error_log off; access_log off;
  server_name ~^(.+)\.rozariofl\.ru$;
  return 301 $scheme://$1.rozarioflowers.ru$request_uri;
  error_log off; access_log off;
}

server { # Redirect from murmansk.rozarioflowers.ru and www.rozarioflowers.ru to rozarioflowers.ru
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/cert/WC_rozariofl_ru.full.crt;
  ssl_certificate_key /etc/letsencrypt/cert/WC_rozariofl_ru.key;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  server_name ~^(murmansk|www)\.rozarioflowers\.ru$;
  return 301 $scheme://rozarioflowers.ru$request_uri;
  error_log off; access_log off;
}

server { # Gag for Yandex fever.
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/cert/WC_rozariofl_ru.full.crt;
  ssl_certificate_key /etc/letsencrypt/cert/WC_rozariofl_ru.key;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  server_name ~^(new|piwik|bot|test123|.*staging.*)\.rozarioflowers\.ru$;
  location = /robots.txt { # Preventively.
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /\nHost: $host\n";
  }
  location / {
    return 444; # https://www.webfx.com/web-development/glossary/http-status-codes/what-is-a-444-status-code/
  }
  # location = / { default_type text/html; return 200 'THANK YOU MARIO! BUT YOUR BUSINESS IS IN ANOTHER CASTLE!'; }
  error_log off; access_log off;
}

server {
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/cert/WC_rozariofl_ru.full.crt;
  ssl_certificate_key /etc/letsencrypt/cert/WC_rozariofl_ru.key;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  server_name ~^(?!adminer\.|.murmansk\.|www\.|new\.|piwik\.|bot\.|test123\.|.*staging.*)[a-z0-9-]*\.?rozarioflowers\.ru$; # Cервер не будет обрабатывать поддомены, начинающиеся с `murmansk.` или `www.` и т.д.
  error_log  /var/log/nginx/rozarioflowers.ru.error.log;
  access_log /var/log/nginx/rozarioflowers.ru.access.log main;
  # # access_log /var/log/nginx/404_access.log detailed_404 if=$log_404;
  # access_log /var/log/nginx/rozarioflowers.ru.access.log main     if=!$log_404; # Обычные логи
  # access_log /var/log/nginx/rozarioflowers.ru.404.log detailed_404 if=$log_404; # Логи курильщика
  # access_log /var/log/nginx/rozarioflowers.ru.goaccess.log ncsa_goaccess;
  include /etc/nginx/bots-block.conf;
  # include /etc/nginx/geoip-block.conf;
  root /srv/rozarioflowers.ru/public;
  passenger_enabled on;
  passenger_app_group_name 'Rozaro Flowers | Padrino web application (production modus)';
  # passenger_app_log_file /var/log/passenger.production.log; # This option is available in Passenger Enterprise only.
  passenger_user admin;
  passenger_ruby /home/admin/.asdf/shims/ruby;
  passenger_nodejs /home/admin/.asdf/shims/node;
  passenger_app_env production;
  passenger_intercept_errors off; # Позволяет перехватить ошибки приложения и отправить пользователя на установленную в настройках Nginx страницу ошибки
  # passenger_memory_limit: 128; passenger_hard_memory_limit: 256; # Preventing memory leaks is only for Phusion Passenger Enterprise :(
  # passenger_app_log_file /var/log/passenger_app.log; # Only for Phusion Passenger Enterprise :(
  passenger_sticky_sessions on;
  passenger_base_uri /;
  passenger_app_root /srv/rozarioflowers.ru;
  passenger_document_root /srv/rozarioflowers.ru/public;
  passenger_min_instances 4; # Всегда 4 прогретых процесса готовых к работе, чтобы минимизировать задержки при внезапных всплесках трафика

  # ---

  include passenger_env/.env.production;

  # ---

  error_page 403             /error/403.html;
  error_page 404             /error/404.html;
  error_page 500 502 503 504 /error/50x.html;
  location = /yandex_a6769fa27997dab4.html { # developer
    default_type text/html; return 200 '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head><body>Verification: a6769fa27997dab4</body></html>';
  }
  more_set_headers 'X-Content-Type-Options: nosniff';
  more_clear_headers -t 'image/webp image/jpeg image/png' 'X-Content-Type-Options'; # Vulnerability legacy. See #KD9F09E
  more_set_headers "Content-Security-Policy: default-src 'self'; script-src 'self' https://cdnjs.cloudflare.com https://unpkg.com/ https://code.jquery.com/ https://lcab.talk-me.ru/ https://mc.yandex.ru/ https://widget.me-talk.ru/; style-src 'self' https://fonts.googleapis.com https://unpkg.com/; font-src https://fonts.gstatic.com;";
  more_set_headers -s '403 404 500 502 503 504' "Content-Security-Policy: default-src 'self';";
  more_set_headers "Content-Security-Policy: upgrade-insecure-requests;";
  more_set_headers 'Permissions-Policy: geolocation=(), camera=(), microphone=(), fullscreen=(self)';
  more_clear_headers X-Powered-By; more_clear_headers Server;

  include abuse_logger;
  include locations/highway_to_hell;
  # include locations/markov_source;
  include locations/admin.prod;
  include locations/payment;
  location = /comment  { return 444; }
  # location /feedback { rewrite ^/feedback(.*)$ /comment$1 break; }
  location ~ ^(.+)/$                        { return 301 $1$is_args$args; } # Редирект для всех адресов, заканчивающихся прямым слэшем, с сохранением передаваемых в строке параметров.
  location ~ ^(.*/)(index\.(html|htm|php))$ { return 301 $1$is_args$args; } # Перенаправление с индексных страниц на базовый URL, с сохранением параметров.
  location / {
    # limit_req zone=antibot burst=20 nodelay;
    expires 1h;
    include /etc/nginx/common_security_headers;
    more_set_headers 'Link: <https://$host$request_uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    passenger_set_header X-Legitimate-Robot $legitimate_robot_header;
    rewrite ^/catalog$      /              permanent;
    rewrite ^/category$     /              permanent;
    rewrite ^/page/comment$ /feedback      permanent; # `/comment` - не используется из-за привлекательности для спам активности. Honey Pot можно туда ставить смело ☝️
    rewrite ^/contacts$     /page/contacts permanent;
    rewrite ^/company$      /page/company  permanent;
    rewrite ^/discount$     /page/discount permanent;
    rewrite ^/dostavka$     /page/dostavka permanent;
    rewrite ^/news/druzhba-%E2%80%93-eto-magiya-magicheskaya-druzhba$ /news/druzhba-eto-magiya-magicheskaya-druzhba permanent; # CRUTCH
    include allowed_list; include disallowed_list; # include deny_all;
  }
  location ~ ^/.+(\.json)(\?.+)?$ { try_files $uri $uri/ @public @grunt @passenger; }
  location @public {
    passenger_enabled off;
    internal;
    root /srv/public/;
    try_files $uri @grunt =404;
  }
  location @grunt {
    passenger_enabled off;
    internal;
    root /srv/grunt/dest/;
    try_files $uri =404; # @passenger;
  }
  location @passenger {
    passenger_sticky_sessions on;
    passenger_base_uri /;
    passenger_app_root /srv/rozarioflowers.ru;
    passenger_document_root /srv/rozarioflowers.ru/public;
    passenger_min_instances 1;
    include proxy_params;
    expires 1h;
    include common_security_headers;
    passenger_set_header X-Legitimate-Robot $legitimate_robot_header;
  }
  location = /favicon.ico {
    access_log off;
    include /etc/nginx/common_security_headers;
    return 204; # The HTTP 204 status code, known as “No Content,” means that the server successfully processed the client's request but does not need to return any content.
  }
  location ~* \.(ttf|woff|woff2|eot|svg)(\?v=[a-zA-Z0-9\.\-_]+)?$ {
    passenger_enabled off;
    if ($redirect_url) { return 301 $redirect_url; } # Link consolidation to SLD. #UD9SSIU3
    try_files $uri @public =404; # @passenger;
    access_log off;
    include common_security_headers;
    more_set_headers 'Link: <https://$root_domain$uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    add_header Cache-Control "public, max-age=31536000, immutable";
    expires 1y; # Устанавливаем срок действия кэша на 1 год
    include common_access_control_headers;
  }
  location ~* ^(.+)\.(png|jpg|jpeg)$ { #KD9F09E
    passenger_enabled off;
    root /srv; # Указываем корневую директорию для оригинальных файлов
    if ($redirect_url) { return 301 $redirect_url; } # Link consolidation to SLD. #UD9SSIU3
    set $path_woext $1; # Извлекаем полный путь до файла без расширения
    set $webp_path /grunt/webp$path_woext.webp; # Создаем полный путь к WebP-версии файла
    set $fallback_path /public$uri; # Создаем полный путь к оригинальной-версии файла
    set $orig_path /grunt/dest$uri;
    try_files $webp_path $orig_path $fallback_path =404; # @passenger; # Если клиент поддерживает WebP, проверяем наличие WebP-версии в отдельной директории
    access_log off;
    include common_security_headers;
    add_header Vary Accept; # Добавляем заголовок Vary, чтобы указать, что ответ зависит от заголовка Accept
    more_set_headers 'Link: <https://$root_domain$uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    add_header Cache-Control "public, max-age=31536000, immutable";
    expires 1y; # Устанавливаем срок действия кэша на 1 год
    include common_access_control_headers;
  }
  location ~* ^.+\.(bmp|webp|gif|svg|js|css|mp3|ogg|mpe?g|avi|zip|gz|bz2?|rar|ico|js|html)(\?v=[a-zA-Z0-9\.\-_]+)?$ {
    passenger_enabled off;
    if ($redirect_url) { return 301 $redirect_url; } # Link consolidation to SLD. #UD9SSIU3
    try_files $uri @public =404;
    access_log off;
    include common_security_headers;
    more_set_headers 'Link: <https://$root_domain$uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    add_header Cache-Control "public, max-age=31536000, immutable";
    expires 1y; # Устанавливаем срок действия кэша на 1 год
    include common_access_control_headers;
  }
  location ~ /\.(ht|svn|git|hg|bzr) { return 444; }
  # location = /robots.txt  { rewrite ^/robots.txt$  /robots/$subdomain/robots.txt  break; }
  # location = /sitemap.xml { rewrite ^/sitemap.xml$ /robots/$subdomain/sitemap.xml break; }
  location = /robots.txt  { root /srv/rozarioflowers.ru/public/robots/$subdomain/; }
  location = /sitemap.xml { root /srv/rozarioflowers.ru/public/robots/$subdomain/; }
  include locations/error;
  include locations/phpmyadmin;
}
