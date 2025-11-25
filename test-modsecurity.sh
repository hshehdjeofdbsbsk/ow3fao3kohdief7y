#!/bin/bash

# Тест ModSecurity конфигурации

echo "=== Тестирование ModSecurity ===" 
echo

# 1. Проверяем синтаксис nginx
echo "1. Проверка синтаксиса Nginx:"
nginx -t
echo

# 2. Проверяем загрузку модуля ModSecurity
echo "2. Проверка загрузки модуля ModSecurity:"
nginx -V 2>&1 | grep -i modsecurity && echo "ModSecurity module found" || echo "ModSecurity module NOT found"
echo

# 3. Проверяем наличие конфигурационных файлов
echo "3. Проверка конфигурационных файлов:"
if [ -f "/app/modsecurity.conf" ]; then
    echo "✓ Основной конфигурационный файл найден"
else
    echo "✗ Основной конфигурационный файл не найден"
fi

if [ -f "/app/custom-modsecurity.conf" ]; then
    echo "✓ Кастомный конфигурационный файл найден"
else
    echo "✗ Кастомный конфигурационный файл не найден"
fi

if [ -f "/etc/modsecurity/crs/crs-setup.conf" ]; then
    echo "✓ Конфигурационный файл CRS найден"
else
    echo "✗ Конфигурационный файл CRS не найден"
fi
echo

# 4. Проверяем права доступа к логам
echo "4. Проверка логов:"
if [ -d "/var/log/nginx" ]; then
    echo "✓ Папка логов nginx существует"
    touch /var/log/nginx/modsec_audit.log 2>/dev/null && echo "✓ Можно создать файл логов ModSecurity" || echo "✗ Нельзя создать файл логов ModSecurity"
else
    echo "✗ Папка логов nginx не существует"
fi
echo

# 5. Проверяем наличие OWASP CRS правил
echo "5. Проверка OWASP CRS правил:"
CRS_RULES_COUNT=$(ls /usr/share/modsecurity-crs/rules/*.conf 2>/dev/null | wc -l)
if [ $CRS_RULES_COUNT -gt 0 ]; then
    echo "✓ Найдено $CRS_RULES_COUNT файлов CRS правил"
else
    echo "✗ CRS правила не найдены"
fi
echo

# 6. Проверяем наличие рабочих директорий
echo "6. Проверка рабочих директорий:"
for DIR in "/tmp/modsecurity" "/var/lib/modsecurity"; do
    if [ -d "$DIR" ]; then
        echo "✓ $DIR существует"
    else
        echo "✗ $DIR не существует"
    fi
done
echo

echo "=== Тест завершен ===" 
