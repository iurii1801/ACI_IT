#!/bin/bash
# Задание 3 - Мониторинг дискового пространства
# Использование: ./disk_monitor.sh <PATH> [THRESHOLD% (по умолчанию 80)]

PATH_TO_CHECK="${1:-/}"
THRESHOLD="${2:-80}"

# 1. Проверка существования пути
if [[ ! -e "$PATH_TO_CHECK" ]]; then
  echo "Ошибка: путь не найден: $PATH_TO_CHECK"
  exit 2
fi

# 2. Получение процента использования через df -h и awk
USAGE=$(df -h "$PATH_TO_CHECK" | awk 'NR==2 {gsub("%","",$5); print $5}')

# 3. Текущая дата и время
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# 4. Вывод информации
echo "$NOW"
echo "Путь: $PATH_TO_CHECK"
echo "Использовано: ${USAGE}%"

# 5. Проверка порога и вывод статуса
if (( USAGE < THRESHOLD )); then
  echo "Статус: OK"
  exit 0
else
  echo "Статус: WARNING: диск почти заполнен!"
  exit 1
fi
