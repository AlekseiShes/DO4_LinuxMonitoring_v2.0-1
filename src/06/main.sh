#! /bin/bash

path_filename=$(readlink -m $0)
delimiter="/" # разделиель каталогов
# Обрезаем строку до последнего вхождения символа, т.е. убираем имя файла скрипта
path="${path_filename%$delimiter*}"

# Цвета текста:
DEF="\033[0;39m"     #  ${DEF}
LRED="\033[31m"      #  ${LRED}
LGREEN='\033[32m'    #  ${LGREEN}
LYELLOW="\033[33m"   #  ${LYELLOW}
LBLUE='\033[34m'     #  ${LBLUE}
LMAGENTA='\033[35m'  #  ${LMAGENTA}
LCYAN='\033[36m'     #  ${LCYAN}
WHITE='\033[37m'     #  ${WHITE}

format="%h\t%s\t%m\t%d\t%t\t%U\t%u" # задаём формат лога (последовательность данных в логфайле), даты и времени
# %h - ip
# %s - code
# %m - ansver
# %d - data "%Y-%m-%d"
# %t - time "%H:%M:%S"
# %U - URL
# %u - user
date_format="%Y-%m-%d"
time_format="%H:%M:%S"

if [ $# != 0 ]; then # не должно быть входных аргументов
    echo -e $LYELLOW"Скрипт работает без параметров. Любые параметры игнорируются."$DEF
fi

#условие проверки наличия файла с правами на выполнение. В данном случае, "-x" проверяет, является ли файл, возвращаемый командой "command -v goaccess", исполняемым.
if ! [ -x "$(command -v goaccess)" ]; then
    echo -e "${LYELLOW}"
    read -p "GoAccess не установлен. Установить? [y/n]: " choice </dev/tty
    echo -e "${DEF}"
        # /dev/tty - Явно указываем, что нужно читать с клавиатуры
    if [[  "${choice,,}" == "y" || "${choice,,}" == "yes" ]]; then
        echo "Установка GoAccess..."
        sudo apt-get install goaccess &>"${path}/"output # &>/dev/null
        if ! [ -x "$(command -v goaccess)" ]; then
            echo -e $LRED "Ошибка при установке GoAccess. Подробности установки в файле '${path}/output'"$DEF
            exit 1
        else
            echo -e $LGREEN "GoAccess установлен!"$DEF
            $(rm -rf "${path}"/output 2>/dev/null)
        fi
    else
        echo -e $LRED "Без установленного GoAccess работа скрипта не возможно." $DEF
        exit 1
    fi
fi

 logpath=$(find "$(readlink -m ${path}/../04/logs)"/* -name "*")

if which xdpyinfo >/dev/null 2>&1; then # проверка есть ли графический интерфейс
    goaccess $logpath --log-format=$format \
        --date-format=$date_format --time-format=$time_format --output="${path}/"index.html # есть
    $(open "${path}/"index.html)
else
    sudo goaccess $logpath  --log-format=$format \
        --date-format=$date_format --time-format=$time_format > "${path}/"goaccess.html # нет
    echo "Посмотреть результат можно тут: "${path}"/goaccess.html (<< Ctrl + Left Click)" #
fi

