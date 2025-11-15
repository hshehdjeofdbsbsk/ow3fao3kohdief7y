# sudo nginx -t && sudo nginx -s reload && sudo systemctl status nginx --no-pager -l

# kill /run/nginx.pid

# sudo passenger-config restart-app /srv/development_rozarioflowers.ru # passenger-config restart-app <path/to/app>
# passenger-status --verbose
# sudo passenger-memory-stats
# passenger-config system-metrics
# passenger-config system-properties
# sudo passenger-status --show=[pool|server|backtraces|xml|json|union_station]
#      passenger-config api-call get /pool.json   | jq . # Получение полной информации о текущем состоянии пула
# sudo passenger-config api-call get /server.json | jq . # Получение текущих обработчиков запросов
# sudo passenger-config api-call get /backtraces.txt     # Backtraces всех тредов
# passenger-status-node # npm i passenger-status-node -g # https://www.npmjs.com/package/passenger-status-node?activeTab=readme
# https://github.com/openresty/headers-more-nginx-module?tab=readme-ov-file#directives
# https://www.phusionpassenger.com/library/config/nginx/reference/

# sudo sed -i 's/<replacement_text>/<replaceable_text>/g' development_rozarioflowers.ru

# sudo apt -y install apache2-utils; sudo htpasswd -c /etc/nginx/.htpasswd [username] # АХТУНГ! Опция `-c` очистит существующий файл пользователей с хэшами!

# sudo certbot certonly --manual --preferred-challenges=dns -d "*.entropyrise.ru" -d entropyrise.ru certonly # https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.entropyrise.ru

upstream app_server { # 🦄 ✖️  🔫
  server unix:/srv/fastapi-app/run/gunicorn.sock fail_timeout=0;
}

server { # 🔴 HTTP gæg
  listen 80;
  # listen [::]:80;
  server_name entropyrise.ru *.entropyrise.ru;
  return 301 https://$host$request_uri; # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
  location = /robots.txt { # Preventively
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /\nHost: $host\n";
  }
}

server { # Redirect from murmansk.entropyrise.ru and www.entropyrise.ru to entropyrise.ru
  listen 443 ssl http2;
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/live/entropyrise.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/entropyrise.ru/privkey.pem;
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  error_log  off; access_log off;
  server_name ~^(murmansk|www)\.entropyrise\.ru$;
  return 301 $scheme://entropyrise.ru$request_uri;
}

passenger_set_header X-Nginx-Passenger-Context http; # 🏷

server {
  listen 443 ssl http2; # 🦻
  # listen [::]:443 ssl http2;
  ssl_certificate     /etc/letsencrypt/live/entropyrise.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/entropyrise.ru/privkey.pem; # 🔑
  include             /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
  server_name ~^(?!adminer\.|.murmansk\.|www\.|piwik\.|bot\.|.*staging.*)[a-z0-9-]*\.?entropyrise\.ru$; # Cервер не будет обрабатывать поддомены, начинающиеся с `murmansk.` или `www.` и т.д.
  error_log  /var/log/nginx/development_rozarioflowers.ru.error.log;  # 📕
  access_log /var/log/nginx/development_rozarioflowers.ru.access.log; # 📘
  # include bots-block.conf;
  # include geoip-block.conf;
  root /srv/development_rozarioflowers.ru/public;
  # modsecurity on; # On/Off ModSecurity WAF
  # modsecurity_rules_file /etc/nginx/modsecurity.conf; # Load ModSecurity CRS
  passenger_enabled on;
  passenger_app_group_name '🌹 Rozaro Flowers 💎 Padrino web application (development modus)';
  # passenger_app_log_file /var/log/passenger.development.log; # This option is available in Passenger Enterprise only
  passenger_user admin; # 
  passenger_ruby /home/admin/.asdf/shims/ruby;
  passenger_nodejs /home/admin/.asdf/shims/node;
  passenger_app_env development;
  passenger_intercept_errors off; # Позволяет перехватить ошибки приложения и отправить пользователя на установленную в настройках Nginx страницу ошибки
  # passenger_memory_limit: 128; passenger_hard_memory_limit: 256; # Preventing memory leaks is only for Phusion Passenger Enterprise :(
  # passenger_app_log_file /var/log/passenger_app.log; # Only for Phusion Passenger Enterprise :(
  passenger_sticky_sessions on; # 🧷
  passenger_base_uri /;
  passenger_app_root /srv/development_rozarioflowers.ru;
  passenger_document_root /srv/development_rozarioflowers.ru/public;
  # passenger_max_requests 666;    # This feature is only available in Phusion Passenger Enterprise
  # passenger_memory_limit 256;    # This feature is only available in Phusion Passenger Enterprise
  # passenger_max_request_time 10; # This feature is only available in Phusion Passenger Enterprise
  passenger_min_instances 1;

  # ---

  include passenger_env/.env.development; # ㊙️  

  # ---

  modsecurity on; # Вкл./выкл.

  error_page 403             /error/403.html;
  error_page 404             /error/404.html;
  error_page 500 502 503 504 /error/50x.html;
  # location = /yandex_a6769fa27997dab4.html {
  #  default_type text/html; return 200 '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head><body>Verification: a6769fa27997dab4</body></html>';
  # }
  more_set_headers 'X-Content-Type-Options: nosniff'; # 🐽
  more_clear_headers -t 'image/webp image/jpeg image/png' 'X-Content-Type-Options'; # Vulnerability legacy. See #KD9F09E
  more_set_headers "Content-Security-Policy: default-src 'self'; script-src 'self' https://cdnjs.cloudflare.com https://unpkg.com/ https://code.jquery.com/ https://lcab.talk-me.ru/ https://mc.yandex.ru/ https://widget.me-talk.ru/; style-src 'self' https://fonts.googleapis.com https://unpkg.com/; font-src https://fonts.gstatic.com;";
  more_set_headers -s '403 404 500 502 503 504' "Content-Security-Policy: default-src 'self';";
  more_set_headers "Content-Security-Policy: upgrade-insecure-requests;"; # 🚨
  more_set_headers 'Permissions-Policy: geolocation=(), camera=(), microphone=(), fullscreen=(self)'; # 👮
  more_clear_headers X-Powered-By; more_clear_headers Server; # 🤙
  passenger_set_header X-Nginx-Passenger-Context server; # 🏷

  include allowed_list; include disallowed_list; include deny_all; # ㊙️

  include abuse_logger; # 🫦 Sweet Dreams 👾
  include locations/highway_to_hell; # 🐐 https://runt-of-the-web.com/jesus-is-a-jerk/#8
  # include locations/markov_source; # Ψ Ⓧ  騒
  include locations/admin.dev; # 🧘‍
  include locations/payment; # 💳
  location /comment  { return 444; } # 🌊
  # location /feedback {
  #   rewrite ^/feedback(.*)$ /comment$1 break;
  #   limit_req zone=antibot burst=20 nodelay;
  # }
  location ~ ^(.+)/$                        { return 301 $1$is_args$args; } # Редирект для всех адресов, заканчивающихся прямым слэшем, с сохранением передаваемых в строке параметров.
  location ~ ^(.*/)(index\.(html|htm|php))$ { return 301 $1$is_args$args; } # Перенаправление с индексных страниц на базовый URL, с сохранением параметров.
  location / { # ENTRY
    limit_req zone=antibot burst=20 nodelay;
    # try_files $uri $uri/ =404; # @passenger;
    expires 1h;
    include common_security_headers;
    more_set_headers 'Link: <https://$host$request_uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    # add_header Nginx-Location-1 "true";
    passenger_set_header X-Nginx-Passenger-Context "location /"; # 🏷
    passenger_set_header X-Legitimate-Robot $legitimate_robot_header; # 🤖
    rewrite ^/catalog$      /              permanent; # 📁
    rewrite ^/category$     /              permanent; # 📁
    rewrite ^/page/comment$ /feedback      permanent; # 🌊 `/comment` - не используется из-за привлекательности для спам активности. Honey Pot можно туда ставить смело ☝️
    rewrite ^/contacts$     /page/contacts permanent; # ✉️
    rewrite ^/company$      /page/company  permanent; # 🌷
    rewrite ^/discount$     /page/discount permanent; # %
    rewrite ^/dostavka$     /page/dostavka permanent; # 🚚
    include allowed_list; include disallowed_list; include deny_all; # ㊙️
  }
  location ~ ^/mini-profiler-resources/.+(\.js|\.css)(\?.+)?$ { try_files $uri $uri/ @passenger; } # 🐬
  location ~ ^/.+/__sinatra__/500.png$                        { try_files $uri $uri/ @passenger; } # 🥃
  location ~ ^/.+(\.json)(\?.+)?$                             { try_files $uri $uri/ @public @grunt @passenger; } # 🔪
  location @public { # 🌏
    passenger_enabled off;
    internal;
    root /srv/public/;
    try_files $uri @grunt =404;
    add_header 'X-Nginx-Location-Public' 'true' always;
  }
  location @grunt { # 🐗 vk.cc/cRk3u6
    passenger_enabled off;
    internal;
    root /srv/grunt/dest/;
    try_files $uri =404; # @passenger;
    add_header 'X-Nginx-Location-Grunt' 'true' always;
  }
  location @passenger { # FWIW 🪗
    passenger_sticky_sessions on;
    passenger_base_uri /;
    passenger_app_root /srv/development_rozarioflowers.ru;
    passenger_document_root /srv/development_rozarioflowers.ru/public;
    # passenger_max_requests 666;    # This feature is only available in Phusion Passenger Enterprise
    # passenger_memory_limit 256;    # This feature is only available in Phusion Passenger Enterprise
    # passenger_max_request_time 10; # This feature is only available in Phusion Passenger Enterprise
    passenger_min_instances 1;
    passenger_set_header X-Nginx-Passenger-Context "location @passenger"; # 🏷
    include proxy_params;
    expires 1h;
    include common_security_headers;
    include common_access_control_headers;
    # modsecurity on;
    add_header 'X-Nginx-Location-Passenger' 'true' always;
  }
  location = /favicon.ico { # ⛩
    passenger_enabled off;
    access_log off;
    include common_security_headers;
    return 204;
  }
  location ~* \.(ttf|woff|woff2|eot|svg)(\?v=[a-zA-Z0-9\.\-_]+)?$ { # 🔤
    passenger_enabled off;
    if ($redirect_url) { return 301 $redirect_url; } # Link consolidation to SLD. #UD9SSIU3
    try_files $uri @public =404; # @passenger;
    access_log off;
    include common_security_headers;
    more_set_headers 'Link: <https://$root_domain$uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    add_header Cache-Control "public, max-age=31536000, immutable";
    expires 1y; # Устанавливаем срок действия кэша на 1 год
    include common_access_control_headers;
    add_header 'X-Nginx-Location-1' '1' always;
  }
  location ~* ^(.+)\.(png|jpg|jpeg)$ { #KD9F09E # 🌅
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
    add_header 'X-Nginx-Location-2' '2' always;
  }
  location ~* ^.+\.(bmp|webp|gif|svg|js|css|mp3|ogg|mpe?g|avi|zip|gz|bz2?|rar|ico|js|html)(\?v=[a-zA-Z0-9\.\-_]+)?$ { # Media 
    passenger_enabled off;
    if ($redirect_url) { return 301 $redirect_url; } # Link consolidation to SLD. #UD9SSIU3
    try_files $uri @public =404;
    access_log off;
    include common_security_headers;
    more_set_headers 'Link: <https://$root_domain$uri>; rel="canonical"'; # RFC 5988 # https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
    add_header Cache-Control "public, max-age=31536000, immutable";
    expires 1y; # Устанавливаем срок действия кэша на 1 год
    include common_access_control_headers;
    add_header 'X-Nginx-Location-3' '3' always;
  }
  location ~ /\.(ht|svn|git|hg|bzr) { return 444; } # 🤔
  location = /robots.txt { passenger_enabled off; default_type text/plain; return 200 "User-agent: *\nDisallow: /\nHost: $host\n"; } # 🤖 https://www.robotstxt.org/
  location = /sitemap.xml { passenger_enabled off; return 444; } # 🔍 SEO
  location ~ ^.+\.(amp)$ { # 🚀
    # default_type text/plain; return 200 "User-agent: *\nDisallow: /\nHost: $host\n";
    passenger_enabled off;
    keepalive_timeout 5;
    client_max_body_size 4G;
    access_log /srv/fastapi-app/log/nginx-access.log; # ✍️ 
    error_log  /srv/fastapi-app/log/nginx-error.log;  # ✍️
    include proxy_params;
    if (!-f $request_filename) {
      proxy_pass http://app_server;
      break; # 🚷
    }
    include allowed_list; include disallowed_list; include deny_all; # ㊙️
  }
  include locations/error; # 4xx, 5xx
  include locations/api_variables; # TRACE
  include locations/api_nginx_status; # STUB
  # include locations/api_passenger_status; # TANSTAAFL
  include locations/fastapi; # 🐍
  include locations/vortex;  # 🌀
  include locations/phpmyadmin; # DB
  include locations/lighthouse; # SEO & performance
  include locations/goaccess; # 📝 ~> 📉 📈 📊
  include locations/monitus;  # 👁  deceptio oculus
  include locations/nginx_variables; # TRACE
  include locations/temp; # Recycle ♻️ 
}

