#! /bin/bash

# bash 03/main.sh 1
regim_debug=0 # 0 - режим по задании, 1 - режим отладки
fieldflood="" # по умолчанию флуд в корне

alias rm='move_to_trash' # алиас - т.е. подмена имен (в данном случае команды функции)
move_to_trash () {      
    echo "9: move_to_trash"
    # mv "$@" ~/.trash # размещение аргументов в карзину
}

# Цветом текста (жирным) (bold) :
DEF="\033[0;39m"     #  ${DEF}
LRED="\033[31m"      #  ${LRED}
LGREEN='\033[32m'    #  ${LGREEN}
LYELLOW="\033[33m"   #  ${LYELLOW}
LBLUE='\033[34m'     #  ${LBLUE}
LMAGENTA='\033[35m'  #  ${LMAGENTA}
LCYAN='\033[36m'     #  ${LCYAN}
WHITE='\033[37m'     #  ${WHITE}

help_h(){
    echo "Помощь: '--help' или '-h'"
    exit $1
}

# Далее из нулевого параметра получаем полный путь к скрипту
path_filename=$(readlink -m $0)
delimiter="/" # разделиель каталогов
# Обрезаем строку до последнего вхождения символа, т.е. убираем имя файла скрипта
path="${path_filename%$delimiter*}"
# это же можно получит так path="$(dirname "$(readlink -m "$0")")"

way=$1 # способ

if [[ $regim_debug == 1 ]]; then
    fieldflood="/home/felisasi/Documents/DO4_LinuxMonitoring_v2.0-1"
fi

# ниже функиция вычисляет номер вхождения слова с строку
getNumberOfWordInStr(){
    # например слово "am"
    # а строка "Hello, World! I am felisasi"
    # тогда ответ будет: 4
    n=0
    for ((i=2;i<=$#;i++)); do
        ((n++))
        if [[ ${!i} == $1 ]]; then
            echo $n
            break
        fi
    done
}

function clean_by_logfile() { # очистка по лог-файлу 2-го задания
    local -n list4del=$1 # возвращаемый список объектов к удалению
    local -n code=$2     # как ссылка, возращаемый параметр, код ошибки
    path_log=$3          # путь к лог-файлу
    consider_uuid=$4     # флаг false - не надо учитывать uuid, true надо
    
    if [[ ! -e $path_log ]]; then
        echo -e $LRED"Объект "$path_log" не существует."$DEF # ругаем
        code=2; return # и ПРОПУСКАЕМ этот аргумент и без прекращение скрипта выходим из функции
    fi

    if [[ ! -f $path_log ]]; then # если это не файл то
        echo -e $LRED"Объект "$path_log" не является файлом."$DEF # ругаем
        code=2; return # и ПРОПУСКАЕМ этот аргумент и без прекращение скрипта выходим из функции
    fi

    headline=$(cat $path_log | awk '{print $0}' | head -1) # берем заголовок
    nPATH=$(getNumberOfWordInStr "PATH" $headline) # узнаем номер столбца в котором путь
    nUUID=$(getNumberOfWordInStr "UUID" $headline) # узнаем номер столбца в котором uuid
    
    if [[ -z $nPATH || -z $nUUID ]]; then # если это не файл то
        echo -e $LRED"Файл "$path_log" не содержит искомых столбцов PATH и UUID."$DEF # ругаем
        code=2; return # и ПРОПУСКАЕМ этот аргумент и без прекращение скрипта выходим из функции
    fi
    # из лог файла извлекаем столцы
    array=$(awk -v c1=$nUUID -v c2=$nPATH 'NF == 7 {print $c1"\t"$c2}' $path_log )
    if [[ $consider_uuid == true ]]; then
        # если нужно учитывать uuid то узнаем его на машине запуска
        currentUUID=$(sudo awk '{print $0}' /sys/class/dmi/id/product_uuid)
    fi
    count_deleted=0
    count__missed=0
    while IFS= read -r line; do # пробегаем по строкам массива
        c_uuid=$(echo $line | awk '{print $1}') # получаем значения uuid
        c_path=$(echo $line | awk '{print $2}') # получаем значения path
        
        if [[ $c_path == "PATH" ]]; then continue; fi

        if [[ $consider_uuid == false  || ( $consider_uuid == true && $c_uuid == $currentUUID ) ]]; then
            if [[ -e $c_path ]]; then
                ((count_deleted++))
                list4del="$list4del $c_path"
                # $(rm -rf ${path}) # удаляет объект
            else
                ((count__missed++))
                echo "miss: "$c_path
            fi
        fi
    done <<< $array

    echo -e $LGREEN"Статистика для файла '"$path_log"':" $DEF
    echo -e "   Найдено для удаления объектов: "$count_deleted
    echo -e "   Не найдено объектов (не существуют): "$count__missed 
}

function clean_by_datetime() {
    local -n list4del=$1 # возвращаемый список объектов к удалению
    local -n code=$2     # как ссылка, возращаемый параметр, код ошибки
    in_data="$3"    # дата в одном из вариантах
    # про передачу третьего параметра подробнее тут:
    # https://stackoverflow.com/questions/1983048/passing-a-string-with-spaces-as-a-function-argument-in-bash
    # "   2023--2024 :                                from 2023-01-01 00:00:00 to 2024-12-31 23:59:59"
    # "   2023-12-30 :                                from 2023-12-30 00:00:00 to 2023-12-30 23:59:59"
    # "   2023-12-30 -- 2024-01:                      from 2023-12-30 00:00:00 to 2023-01-31 23:59:59"
    # "   '2023-12-31 23:50 -- 2024-01-01 00:15:53' : from 2023-12-31 23:50:00 to 2024-01-01 00:15:53"
    # "   '2024-01-01 23' :                           from 2024-01-01 23:00:00 to 2024-01-01 23:59:59"
    delimiter="--" # разделиель дат
    data_start=$(echo $in_data | awk -F '--' '{print $1}')
    data_stop=$(echo $in_data | awk -F '--' '{print $2}')
    # echo "data_start=${data_start}"
    # echo "data_stop=${data_stop}"

    if [[ -z $data_stop ]]; then data_stop=$data_start; fi 
    # ниже с применением тернального оператора реализация кода выше
    # data_stop=$([ -z "$data_stop" ] && echo "$data_start" || echo "$data_stop")

    d_start=$(source "${path}/datatime_restore.sh" "$data_start")
    code=$? ; if [[ $code -ne 0 ]]; then echo -e "\033[31m Ошибка в дате: $data_start: $d_start \033[0m"; return; fi

    d_end=$(source "${path}/datatime_restore.sh" "${data_stop}" "up")
    code=$? ; if [[ $code -ne 0 ]]; then echo -e "\033[31m Ошибка в дате: $data_stop: $d_end \033[0m"; return; fi
    
    if [[ "$(date -d "${d_end}" +%s)" -le "$(date -d "${d_start}" +%s)" ]]; then
        echo -e "$LYELLOW Дата-Время: $d_start раньше, чем: $d_end, поэтому они переставлены $DEF"
        d_start=$(source "${path}/datatime_restore.sh" "$data_stop")
        d_end=$(source "${path}/datatime_restore.sh" "$data_start" "up")
    fi 

    echo "По интервалу времени [ $d_start >> $d_end ] поиск объектов..."
    count_deleted=0
    for c_path in $( # проходка по всем файлам и папкам системы
        find ${fieldflood}/* -name "*" 2>/dev/null
    ); do
        inode=$(stat -c "%i" ${c_path} 2>/dev/null) # вытащили inode файла/папки
        human_dat=$(sudo debugfs -R "stat <${inode}>" \
            $(df ${c_path} | awk 'NR==2 {print $1}') 2>/dev/null |
            awk '/crtime/ {print $6" "$5" "$8" "$7}')   # дата создания файла в формате например 6 Nov 2023 00:53:33
        formatted_dat=$(date -d "$human_dat" +"%Y-%m-%d %H:%M:%S") # преобразование даты в вид date
        if [[ "$(date -d "${d_start}" +%s)" -le "$(date -d "${formatted_dat}" +%s)" &&
              "$(date -d "${d_end}" +%s)" -ge "$(date -d "${formatted_dat}" +%s)" ]]; then # если дата файла/папки соответ. промежутку
                ((count_deleted++))
                list4del="$list4del $c_path"
                #$(rm -rf ${c_path}) # удаляем
        fi
    done
    echo -e $LGREEN"Статистика по интервалу времени [ $d_start >> $d_end ]. Найдено для удаления объектов в колличестве: "$count_deleted $DEF
}

function clean_by_mask() {
    local -n list4del=$1 # возвращаемый список объектов к удалению 
    mask=$2              # маска
    count_deleted=0
    for c_path in $( # проходка по всем файлам и папкам системы
        find ${fieldflood}/* -name "$mask" 2>/dev/null # -wholename "$mask"
    ); do  # запись 2>/dev/null подавляет вывод ошибок на экран
        ((count_deleted++))
        list4del="$list4del $c_path"
        #$(rm -rf ${file}) # удаляем
    done
    echo -e $LGREEN"Статистика для маски '"$mask"': найдено для удаления объектов: "$count_deleted $DEF
}


# Проверяем кол-во и качество входных параметров
if [ "$#" -eq 1 ] && [[ "$way" =~ ^(--help|-h)$ ]]; then
    echo "Очистка разными методами"
    echo "Описание: пример"
    echo "По лог-файлам: 1 /home/user1/logfile1.log ../logfile2.log и т.д."
    echo "   Используйте флаг consider чтоб учитывать uuid расположения файла: --consider=uuid"
    echo "По времени создания: 2 2023--2024 2023-12-30 '2023-12-30 -- 2024-01' '2023-12-31 23:50 -- 2024-01-01 00:15:53' '2024-01-01 23'"
    echo "   2023--2024 :                                from 2023-01-01 00:00:00 to 2024-12-31 23:59:59"
    echo "   2023-12-30 :                                from 2023-12-30 00:00:00 to 2023-12-30 23:59:59"
    echo "   '2023-12-30 -- 2024-01':                    from 2023-12-30 00:00:00 to 2023-01-31 23:59:59"
    echo "   '2023-12-31 23:50 -- 2024-01-01 00:15:53' : from 2023-12-31 23:50:00 to 2024-01-01 00:15:53"
    echo "   '2024-01-01 23' :                           from 2024-01-01 23:00:00 to 2024-01-01 23:59:59"
    echo "По маскам названия файла: 3 *_311223 *010124*"
    exit 0
elif [ "$#" -gt 1 ] && [[ $way =~ ^[1-3]+$ ]]; then
    # далее проверяем нужно ли учитывать (consider) номер машины (uuid) к которой относится директория 
    consider=$( [[ $way -eq 1 && ($* == *" --consider=uuid "* || ${@: -1} == "--consider=uuid") ]] && echo true || echo false )
    # вся строка $* содержит любые символы (*) до и после " --consider=uuid " или если это последний параметр ${@: -1}
    # далее пробегаемся по всем параметрам (лог-файлы, даты, маски)
    code_exit=0
    curr_code=0
    LIST_DELETE=""

    echo "Процесс запущен!"
    for ((i=2;i<=$#;i++)); do
        echo "Ожидайте результат!"
        case $way in # $way - режим(способ) (1 или 2 или 3)
            1)  if [[ ! ($consider==true && ${!i} == "--consider=uuid") ]]; then
                    clean_by_logfile LIST_DELETE curr_code ${!i} $consider # отправляем если это не флаг 
                fi ;;
            2)  
                clean_by_datetime LIST_DELETE curr_code "${!i}";; # detail: https://stackoverflow.com/questions/1983048/passing-a-string-with-spaces-as-a-function-argument-in-bash
            3) 
                clean_by_mask "LIST_DELETE '${!i}'";;
        esac
        if (( curr_code!=0 )); then code_exit=$curr_code ; fi
    done

    Total_count=$(echo $LIST_DELETE | wc -w) 
    echo -e "${LYELLOW}Общее число объектов для удаления: $Total_count."
    if (( Total_count < 1 )); then
        exit $code_exit; fi
    read -p "Показать их ? [y/n]: " choice </dev/tty
    echo -e "${DEF}"
    if [[  "${choice,,}" == "y" || "${choice,,}" == "yes" ]]; then
        iter=1
        echo "Список объектов к удалению:"
        for c_path in $LIST_DELETE ; do
            echo -e "${iter}:\t${c_path}"
            ((iter++))       
        done 
    fi

    echo -e "${LYELLOW}"
    read -p "Удалить их ? [y/n]: " choice </dev/tty
    echo -e "${DEF}"
    if [[  "${choice,,}" == "y" || "${choice,,}" == "yes" ]]; then
        for c_path in $LIST_DELETE ; do 
            if [[ -e $c_path && ( ! $regim_debug == 1) ]]; then 
                $(rm $c_path -rf) # удаляем
            fi
        done
        echo "Объекты успешно удалены!"
    else
        echo "Удаление отменено!"
    fi

    exit $code_exit
else
    echo -e $LRED"Укажите режим очистки (N=1, 2 или 3) и как минимум ещё один параметр."$DEF
    help_h 1
fi
