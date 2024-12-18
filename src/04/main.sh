#! /bin/bash

regim_debug=0 # 0 - режим по задании, 1 - режим отладки

path="$(dirname "$(readlink -m "$0")")"

source $path/included_file.sh # в такой записи выглядик как аналог #include<*.h> 

$(mkdir "$path/logs" 2>/dev/null)           # создаём папку для лог-файлов
countOfLogfiles=5                           # кол-во лог-файлов (по заданию)
Rec_min=100                                 # минимальное число записей в лог-файле
Rec_max=1000                                # максимальное число записей в лог-файле
if [[ $regim_debug == 1 ]]; then
    Rec_min=10  
    Rec_max=25 
fi
dayInSec=$(date -d $(date +"%Y-%m-%d") +%s) # сегодняшняя дата в секундах
SecPerDay=86400                             # количество секунд в сутках 
((dayInSec-=SecPerDay*(countOfLogfiles-1))) # сдвигаемся на countOfLogfiles дней назад
rec_summ=0                                  # общее число созданных файлов

for ((i = 1; i <= countOfLogfiles; i++)); do # цикл отвечающий за создание файлов
    dat=$dayInSec                            # меняем dayInSec для файла, а dat для записи   
    logfilename="$path/logs/logfile${i}_$(date -d @${dayInSec} +"%Y-%m-%d").log"
    $(touch $logfilename)                    # добавляем файл лога
    rand_CountOfRecords=$(shuf -i $Rec_min-$Rec_max -n 1)
    # rand_CountOfRecords - кол-во логов(запись) в файле (в указанном диапазоне)
    for ((j = 0; j < rand_CountOfRecords; j++)); do # цикл отвечающий за кол-во записей
        StepSec=$(shuf -i 0-$(((dayInSec+SecPerDay-dat)/(rand_CountOfRecords-j))) -n 1)
        # StepSec - кол-во добавляемых секунд для даты лога
        let dat+=StepSec                    
        code=${codes[  $((RANDOM % ${#codes[@]})) ]}
        echo -e "$(shuf -n 1 <$path/ip \
              )\t$code\t$(shuf -n 1 <$path/methods \
              )\t$(date -d @${dat} +"%Y-%m-%d\t%H:%M:%S" \
              )\t$(shuf -n 1 <$path/url \
              )\t$(shuf -n 1 <$path/agents \
            )" >> $logfilename
    done
    let dayInSec+=SecPerDay                 # прибавляем один день
    ((rec_summ+=rand_CountOfRecords))       # сквозная сумма количества записей 
done
echo "В "$countOfLogfiles" файле(-ах) создано записей: "$rec_summ
