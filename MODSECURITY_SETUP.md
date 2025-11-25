# ModSecurity для Nginx - Руководство по настройке

## Обзор

ModSecurity - это веб-приложение firewall (WAF), которое обеспечивает защиту от различных веб-атак, включая:

- SQL injection
- Cross-site scripting (XSS)
- Cross-site request forgery (CSRF)
- DDoS атаки
- Загрузка вредоносных файлов
- Брутфорс атаки

## Установленные компоненты

1. **ModSecurity 3.0.12** - основной движок WAF
2. **OWASP Core Rule Set (CRS) 3.3.5** - набор правил безопасности
3. **Nginx модуль** - интеграция с веб-сервером

## Структура файлов

```
/app/
├── modsecurity.conf                    # Основная конфигурация ModSecurity
├── custom-modsecurity.conf            # Пользовательские правила
├── modules-enabled/
│   └── 50-mod-http-modsecurity.conf   # Загрузка модуля
├── conf.d/
│   ├── bad-user-agents.txt           # Список подозрительных User-Agent
│   └── spam-keywords.txt             # Список спам-ключевых слов
└── test-modsecurity.sh               # Скрипт тестирования

/etc/modsecurity/crs/
└── crs-setup.conf                    # Конфигурация OWASP CRS

/usr/share/modsecurity-crs/
└── rules/                            # 32 файла правил OWASP CRS
```

## Основные настройки

### Уровень параноидальности (Paranoia Level)

- **Level 1** (текущий): Базовая безопасность, подходит для продакшена
- **Level 2**: Расширенная безопасность, может вызывать ложные срабатывания
- **Level 3-4**: Экспериментальные правила с высоким риском ложных срабатываний

### Режим работы

- **DetectionOnly**: Только обнаружение и логирование (безопасный режим)
- **On**: Полная защита с блокировкой атак (текущий режим)

### Пороги аномалий

- **Inbound threshold**: 5 (блокировка входящих запросов)
- **Outbound threshold**: 4 (блокировка исходящих ответов)

## Логирование

### Файлы логов

- **Audit log**: `/var/log/nginx/modsec_audit.log`
- **Error log**: `/var/log/nginx/development_rozarioflowers.ru.error.log`
- **Access log**: `/var/log/nginx/development_rozarioflowers.ru.access.log`

### Что логируется

- Все заблокированные запросы
- Подозрительная активность
- Ошибки сервера (4xx, 5xx)
- Детали каждой атаки

## Пользовательские правила

### Защита от брутфорса

```apache
# Ограничение POST запросов: максимум 20 за 60 секунд
SecRule REQUEST_METHOD "@streq POST" \
    "id:999200,phase:1,pass,nolog,initcol:ip=%{remote_addr},setvar:ip.post_count=+1,expirevar:ip.post_count=60"
```

### Блокировка опасных файлов

```apache
# Блокировка загрузки исполняемых файлов
SecRule FILES_NAMES "@rx \.(php|exe|sh|bat|cmd)$" \
    "id:999500,phase:2,deny,status:403,msg:'Dangerous file type upload blocked'"
```

### Защита админ-панели

```apache
# Блокировка доступа к /admin (кроме localhost)
SecRule REQUEST_URI "@beginsWith /admin" \
    "id:999300,phase:1,deny,status:404,msg:'Access to admin panel blocked'"
```

## Команды управления

### Тестирование конфигурации

```bash
# Проверка синтаксиса Nginx
nginx -t

# Полное тестирование ModSecurity
./test-modsecurity.sh
```

### Перезагрузка конфигурации

```bash
# Перезагрузка Nginx без остановки
nginx -s reload

# Перезапуск Nginx
systemctl restart nginx
```

### Просмотр логов

```bash
# Просмотр последних записей аудита
tail -f /var/log/nginx/modsec_audit.log

# Анализ заблокированных запросов
grep -i "denied" /var/log/nginx/modsec_audit.log

# Статистика по IP-адресам
grep "client:" /var/log/nginx/modsec_audit.log | awk '{print $4}' | sort | uniq -c | sort -nr
```

## Настройка для российского контента

### Поддержка кириллицы

```apache
# Исключение для кириллических символов
SecRuleRemoveById 920273

# Настройка UTF-8
SecAction "id:900950,phase:1,nolog,pass,t:none,setvar:tx.crs_validate_utf8_encoding=0"
```

### Геоблокировка (опционально)

```apache
# Разрешить только СНГ страны
SecRule TX:COUNTRY_CODE "!@rx ^(RU|BY|KZ|UA|AM|AZ|GE|KG|MD|TJ|TM|UZ)$" \
    "id:999601,phase:1,deny,status:403,msg:'Access denied from country: %{tx.country_code}'"
```

## Мониторинг и отладка

### Основные метрики

- Количество заблокированных запросов в час
- Топ IP-адресов атакующих
- Наиболее частые типы атак
- Ложные срабатывания

### Отладка ложных срабатываний

1. Найдите ID правила в логе
2. Временно отключите правило:
   ```apache
   SecRuleRemoveById RULE_ID
   ```
3. Создайте исключение для конкретного случая
4. Перезагрузите конфигурацию

### Создание whitelist

```apache
# Исключение для доверенных IP
SecRule REMOTE_ADDR "@ipMatch 192.168.1.0/24" \
    "id:999001,phase:1,pass,nolog,ctl:ruleEngine=Off"

# Исключение для статических ресурсов
SecRule REQUEST_URI "@rx \.(css|js|png|jpg|gif)$" \
    "id:999900,phase:1,pass,nolog,ctl:ruleEngine=Off"
```

## Безопасность

### Рекомендации

1. **Регулярно обновляйте** OWASP CRS правила
2. **Мониторьте логи** на предмет новых типов атак
3. **Настройте алерты** для критических событий
4. **Тестируйте** изменения на staging окружении
5. **Создавайте резервные копии** конфигурации

### Производительность

- ModSecurity добавляет ~2-5ms латентности
- Используйте кеширование для статических ресурсов
- Настройте исключения для легитимного трафика
- Мониторьте использование CPU и памяти

## Решение проблем

### Частые проблемы

1. **ModSecurity не загружается**
   - Проверьте наличие модуля: `nginx -V 2>&1 | grep modsecurity`
   - Убедитесь, что модуль загружен в `modules-enabled/`

2. **Ложные срабатывания**
   - Найдите ID правила в audit log
   - Создайте исключение или настройте whitelist

3. **Высокая нагрузка**
   - Уменьшите paranoia level
   - Добавьте исключения для статических ресурсов
   - Оптимизируйте custom правила

4. **Логи не записываются**
   - Проверьте права доступа к директории логов
   - Убедитесь, что путь к логам корректен

### Полезные команды

```bash
# Проверка статуса ModSecurity
nginx -V 2>&1 | grep -i modsecurity

# Подсчет правил
grep -r "id:" /usr/share/modsecurity-crs/rules/ | wc -l

# Анализ производительности
grep "ModSecurity" /var/log/nginx/error.log

# Поиск конкретной атаки
grep "SQL Injection" /var/log/nginx/modsec_audit.log
```

## Дополнительные ресурсы

- [OWASP ModSecurity Documentation](https://owasp.org/www-project-modsecurity/)
- [OWASP CRS Documentation](https://coreruleset.org/docs/)
- [ModSecurity Reference Manual](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual)
- [Nginx ModSecurity Module](https://github.com/SpiderLabs/ModSecurity-nginx)

---

**Версия документации**: 1.0  
**Дата создания**: 25 ноября 2025  
**ModSecurity версия**: 3.0.12  
**OWASP CRS версия**: 3.3.5  
