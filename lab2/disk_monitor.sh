#!/bin/bash
# Задание 3 - Мониторинг дискового пространства
# Использование: ./disk_monitor.sh <PATH> [THRESHOLD% (по умолчанию 80)]

PATH_TO_CHECK="${1:-/}"
THRESHOLD="${2:-80}"

# 1. Проверки
if [[ ! -e "$PATH_TO_CHECK" ]]; then
  echo "Ошибка: путь не найден: $PATH_TO_CHECK"
  exit 2
fi
# если порог передали не числом — вернём к 80
[[ "$THRESHOLD" =~ ^[0-9]+$ ]] || THRESHOLD=80

# 2. Берём процент занятости с df
# -P даёт стабильный POSIX-формат, 5-й столбец — Used%
USAGE=$(df -P "$PATH_TO_CHECK" | awk 'NR==2{gsub("%","",$5); print $5}')

# 3. Вывод по формату
NOW=$(date '+%Y-%m-%d %H:%M:%S')
echo "$NOW"
echo "Путь: $PATH_TO_CHECK"
echo "Использовано: ${USAGE}%"

# 4. Статус и код возврата
if (( USAGE < THRESHOLD )); then
  echo "Статус: OK"
  exit 0
else
  echo "Статус: WARNING: диск почти заполнен!"
  exit 1
fi
