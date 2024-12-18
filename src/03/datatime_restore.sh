#!/bin/bash

input_date=$1 # 'YYYY-MM-DD HH:MM:SS' или 'YYYY' но не короче

if [ -z $2 ]; then
  switchD=1 # минимизация даты времени (по умолчанию)
else
  switchD=2 # любой символ -> то максимизация даты времени
fi

# Разделение введенной на части: берем дату
pdata=$(echo $input_date | awk -F ' ' '{print $1}')

  # Разделение введенной даты на части
  year=$(echo $pdata | awk -F '-' '{print $1}')
  if [ -z $year ]; then
    return
  fi

  month=$(echo $pdata | awk -F '-' '{print $2}')
    repl=$(echo "01 12" | awk -v c=$switchD '{print $c}')
    month=$(echo $month $repl | awk -F ' ' '{print $1}')

  day=$(echo $pdata | awk -F '-' '{print $3}')
    # Определение последнего дня для заданного месяца и года
    last_day=$(cal $month $year 2>/dev/null | awk 'NF {DAYS = $NF}; END {print DAYS}')
    if [ -z $last_day ]; then
      echo "Ошибка в месяце, введите другие данные"
      exit 2
    fi
    repl=$(echo "01 "$last_day | awk -v c=$switchD '{print $c}')
    day=$(echo $day $repl | awk -F ' ' '{print $1}')

# Разделение введенной на части: берем время
ptime=$(echo $input_date | awk -F ' ' '{print $2}')

  # Разделение введенной время на части
  hour=$(echo $ptime | awk -F ':' '{print $1}')
  repl=$(echo "00 23" | awk -v c=$switchD '{print $c}')
  hour=$(echo $hour $repl | awk -F ' ' '{print $1}')

  minute=$(echo $ptime | awk -F ':' '{print $2}')
  repl=$(echo "00 59" | awk -v c=$switchD '{print $c}')
  minute=$(echo $minute $repl | awk -F ' ' '{print $1}')

  secunds=$(echo $ptime | awk -F ':' '{print $3}')
  secunds=$(echo $secunds $repl | awk -F ' ' '{print $1}')

# Формирование полной даты и вывод
date_string="$year-$month-$day $hour:$minute:$secunds"

if date -d "$date_string" >/dev/null 2>&1; then
  echo $date_string
else
  echo "Дата и время некорректны"
  exit 2
fi