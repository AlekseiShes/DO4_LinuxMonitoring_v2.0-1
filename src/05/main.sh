#! /bin/bash

path="$(dirname "$(readlink -m "$0")")"

# Цвета текста:
DEF="\033[0;39m"     #  ${DEF}
LRED="\033[31m"      #  ${LRED}
LGREEN='\033[32m'    #  ${LGREEN}
LYELLOW="\033[33m"   #  ${LYELLOW}
LBLUE='\033[34m'     #  ${LBLUE}
LMAGENTA='\033[35m'  #  ${LMAGENTA}
LCYAN='\033[36m'     #  ${LCYAN}
WHITE='\033[37m'     #  ${WHITE}

MAX_LINES=20 #число строк, свыше которого предупреждать о выводе или сохранять в файл

help_h(){
    echo "Помощь: '--help' или '-h'"
    exit $1
}

# Проверяем кол-во и качество входных параметров
if [ "$#" -eq 1 ] && [[ "$1" =~ ^(--help|-h)$ ]]; then
    echo "Должен быть только один параметр:"
    echo "1 - Все записи, отсортированные по коду ответа"
    echo "2 - Все уникальные IP, встречающиеся в записях"
    echo "3 - Все запросы с ошибками (код ответа - 4хх или 5хх)"
    echo "4 - Все уникальные IP, которые встречаются среди ошибочных запросов"
    exit 0
elif [ $# -ne 1 ]; then # проверка на кол-во параметров
    echo "Должен быть хоты бы/лишь один параметр!"
    help_h 2 # 2 - код ошибки о не хватке параметров
elif [[ ! $1 =~ ^[1-4]+$ ]]; then # проверка на корректность ввода
    echo "Параметром должно быть число от 1 до 4"
    help_h 1 # 1 - код ошибки о не корректности параметров
else
    count_files=0
    pathlog=$(readlink -m "$path/../04/logs")

    for file in $(find $pathlog/* -name "*"); do # проходка по всем файлам
        ((count_files++))
        $(cat $file >> tempfile)
    done
    
    count_rows=$(cat tempfile | sed '/^\s*$/d' | wc -l)

    case "$1" in
        1) # сортируем по коду ответа и записываем в файл вывода
           awk '{print $0}' tempfile | sort -k2 > temp_out;;
        2) # выводим в файл output только уникальные ip
           # uniq и '!seen[$1]++' делают одно и тоже
           # awk '{print $1}' tempfile | uniq > temp_out;; -- не работает!
           awk '!seen[$1]++' tempfile | awk '{print $1}' >temp_out;;
        3) # сортируем по коду ответа 4xx и 5xx
            awk '$2 ~ /^[4-5]/{print $0}' tempfile > temp_out ;; 
        4) # выводим в файл output только уникальные ip (для ответов 4xx и 5xx)
           awk '$2 ~ /^[4-5]/{print $0}' tempfile > temp2
           awk '!seen[$1]++' temp2 | awk '{print $1}' >temp_out
           $(rm -rf temp2 2>/dev/null);; 
    esac
    $(rm -rf temp 2>/dev/null)

    count_nonblank=$(cat temp_out | sed '/^\s*$/d' | wc -l)
    #echo "count_nonblank="$count_nonblank
    output="/dev/stdout"
    if (( count_nonblank >= MAX_LINES )); then
        output="$path/result_query_"$1"_$(date +"%Y-%m-%d-%H-%M-%S").log"
        echo -e "${LYELLOW}Резальтат содержит строк: "$count_nonblank"." \
                "Быть может результат сохранить в выходном файле? Если нет, то результат будет выведен на экран."
        read -p "Сохранить результат в файл '$output'? [y/n]: " choice </dev/tty
            # /dev/tty - Явно указываем, что нужно читать с клавиатуры
        if [[ !( "${choice,,}" == "y" || "${choice,,}" == "yes" ) ]]; then
            echo -e "${DEF}"
            output="/dev/stdout"
        fi
    fi
    echo -e "$(awk '{print $0}' temp_out)" > $output
    $(rm -rf temp_out 2>/dev/null)

    if (( count_files == 0 )); then
        echo -e $LRED"Файлов в ../04/logs/ не найдено!"$DEF
    else 
        echo -e $LGREEN"Проанализировано файлов: "$count_files", с общим число записей в них: "$count_rows $DEF
    fi
    rm -fv tempfile
fi
