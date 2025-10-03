#!/bin/bash
# Задание 2 - Резервное копирование каталога с логированием и ротацией
# Использование: ./backup_rot.sh <SRC_DIR> [DST_DIR=~/backups] [KEEP=7]

SRC="$1"
DST="${2:-$HOME/backups}"
KEEP="${3:-7}"
TS="$(date '+%Y%m%d_%H%M%S')"

# 1. Проверки аргументов
if [[ -z "$SRC" ]]; then
  echo "Ошибка: укажите каталог-источник." >&2
  echo "Пример: $0 /home/user/data ~/backups 5" >&2
  exit 2
fi
if [[ ! -d "$SRC" ]]; then
  echo "Ошибка: источник не существует или не каталог: $SRC" >&2
  exit 2
fi

# 2. Каталог бэкапов и право на запись
mkdir -p -- "$DST" || { echo "Ошибка: не создать $DST" >&2; exit 3; }
if ! touch "$DST/.write_test" 2>/dev/null; then
  echo "Ошибка: нет прав на запись в $DST" >&2
  exit 4
fi
rm -f -- "$DST/.write_test"

# 3. Создание архива (с защитой от пробелов)
BASE="$(basename "$SRC")"
FILE="backup_${BASE}_${TS}.tar.gz"
ARCHIVE="$DST/$FILE"

if tar -czf "$ARCHIVE" -C "$(dirname "$SRC")" "$BASE"; then
  STATUS=0
else
  STATUS=$?
fi

# 4. Размер для лога (если архив создан)
SIZE="0B"
[[ -f "$ARCHIVE" ]] && SIZE="$(du -h "$ARCHIVE" | awk '{print $1}')"

# 5. Ротация: оставить только KEEP свежих архивов данного BASE
ls -1t "$DST"/backup_"$BASE"_*.tar.gz 2>/dev/null \
  | tail -n +$((KEEP+1)) \
  | xargs -r -d '\n' rm -f --

# 6. Лог
echo "$(date -Iseconds) SRC=$SRC DST=$DST FILE=$FILE SIZE=$SIZE STATUS=$STATUS" >> "$DST/backup.log"

exit "$STATUS"
