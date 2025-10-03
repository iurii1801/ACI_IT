#!/bin/bash
# Задание 1 — CLI-ассистент

# 1. Ввод имени с проверкой
attempts=0
while [[ $attempts -lt 3 ]]; do
    read -r -p "Введите ваше имя: " name
    if [[ -n $name ]]; then
        break
    fi
    echo "Имя не может быть пустым. Попробуйте снова."
    ((attempts++))
done

if [[ -z $name ]]; then
    echo "Слишком много неудачных попыток. Завершение работы."
    exit 1
fi

# 2. Ввод отдела
read -r -p "Введите ваш отдел/группу (необязательно): " dept
if [[ -z $dept ]]; then
    dept="не указан"
fi

# 3. Мини-отчёт
current_date=$(date)
host_name=$(hostname)
uptime_info=$(uptime -p)
free_space=$(df -h / | awk 'NR==2{print $4}')
user_count=$(who | wc -l)

echo "------------------------------"
echo "Текущая дата: $current_date"
echo "Имя хоста: $host_name"
echo "Аптайм системы: $uptime_info"
echo "Свободное место на /: $free_space"
echo "Пользователей в системе: $user_count"
echo "------------------------------"

# 4. Приветствие
echo "Здравствуйте, $name ($dept)!"
