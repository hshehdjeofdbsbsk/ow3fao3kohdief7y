# FastAPI Proxy Cache Configuration

## 🎯 Что добавлено

Добавлена конфигурация nginx proxy_cache для кэширования FastAPI приложений в трех файлах:

### 1. **sites-available/passenger**
```nginx
location ^~ /fastapi/ {
  proxy_cache cache;
  proxy_cache_valid 200 302 10m;  # 10 минут для успешных ответов
  proxy_cache_valid 404 1m;       # 1 минута для 404 ошибок
  proxy_cache_bypass $no_cache;   # Обход для залогиненных пользователей
  add_header X-Cache-Status $upstream_cache_status always;
}
```

### 2. **sites-available/development_rozarioflowers.ru**
```nginx
location ~ ^.+\.(amp)$ {
  # Аналогичные настройки кэша для .amp endpoints
  proxy_cache cache;
  proxy_cache_valid 200 302 10m;
  proxy_cache_valid 404 1m;
}
```

### 3. **sites-available/fastapi-app**  
```nginx
location / {
  # Более длительное кэширование для standalone приложения
  proxy_cache cache;
  proxy_cache_valid 200 302 15m;  # 15 минут
  proxy_cache_valid 404 5m;       # 5 минут
}
```

## 🔍 Как проверить работу

### Через curl:
```bash
# Первый запрос - MISS
curl -I https://your-domain/fastapi/endpoint

# Второй запрос - HIT  
curl -I https://your-domain/fastapi/endpoint

# Ищите заголовки:
# X-Cache-Status: HIT|MISS|EXPIRED|STALE
# X-Cache-Key: your-domain/fastapi/endpoint
```

### Через браузер:
- F12 → Network → Headers
- Смотрите X-Cache-Status в response headers

## 🛡️ Cache Bypass Logic

Кэш автоматически обходится для:
- Пользователей с cookie содержащими 'SESS'
- Пользователей WordPress (cookie 'wordpress_logged_in')

Для добавления своих условий:
```nginx
# В nginx.conf
map $http_cookie $no_cache {
  default 0;
  ~your_session_cookie 1;
}
```

## 📊 Monitoring

```bash
# Размер кэша
du -sh /var/cache/nginx/

# Очистка кэша
sudo rm -rf /var/cache/nginx/*

# Проверка статуса
nginx -t && nginx -s reload
```

## ⚡ Performance Benefits

- **Снижение нагрузки** на FastAPI приложения
- **Быстрый отклик** для повторных запросов (HIT из кэша)
- **Защита от перегрузки** при высоком трафике
- **Graceful degradation** при ошибках upstream (stale cache)

---

✅ **Конфигурация протестирована и готова к использованию**
