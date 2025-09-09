#!/bin/bash
# Файл /usr/local/bin/monitoring-script.sh
# Systemd юнит в /etc/systemd/system/monitoring.service
# Таймер для юнита на /etc/systemd/system/monitoring.timer (Первый запуск через минуту после старта системы)
# Настройки
LOG_FILE="/var/log/monitoring.log"
API_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/tmp/monitoring_state.txt"
 
# Функция для записи в лог
write_to_log() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $message" >> "$LOG_FILE"
}
 
# Проверяем, запущен ли процесс test
pgrep -x "$PROCESS_NAME" > /dev/null
process_status=$?
 
# Если процесс запущен (status = 0)
if [ $process_status -eq 0 ]; then
    # Делаем запрос к API
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$API_URL")
    
    # Если сервер не ответил 200 OK
    if [ "$http_code" != "200" ]; then
        write_to_log "ERROR: Monitoring server unavailable. HTTP code: $http_code"
    fi
    
    current_state="running"
else
    current_state="stopped"
fi
 
# Проверяем, был ли перезапуск процесса
if [ -f "$STATE_FILE" ]; then
    previous_state=$(cat "$STATE_FILE")
else
    previous_state="unknown"
fi
 
# Сохраняем текущее состояние
echo "$current_state" > "$STATE_FILE"
 
# Если процесс был остановлен, а теперь запущен - это перезапуск
if [ "$previous_state" = "stopped" ] && [ "$current_state" = "running" ]; then
    write_to_log "INFO: Process $PROCESS_NAME was restarted"
fi
 
# Завершаем скрипт
exit 0