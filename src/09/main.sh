#! /bin/sh
# bash 09/main.sh

path_filename=$(readlink -m $0)
delimiter="/" # разделиель каталогов
# Обрезаем строку до последнего вхождения символа, т.е. убираем имя файла скрипта
path="${path_filename%$delimiter*}"
FILE="${path}/index.html"
# Цвета текста:
DEF="\033[0;39m"     #  ${DEF}
LYELLOW="\033[33m"   #  ${LYELLOW}
LMAGENTA='\033[35m'  #  ${LMAGENTA}
L_BRA=""
R_BRA=""
LDECBRA=""
RDECBRA=""
read -p "Сохранить результат с html разметкой? [y/n]: " choice </dev/tty
if [[ ( "${choice,,}" == "y" || "${choice,,}" == "yes" ) ]]; then
    L_BRA="<p>"
    R_BRA="</p>"
    LDECBRA="<!DOCTYPE html>\n<html>\n<body>"
    RDECBRA="</body>\n</html>"
    choice=1
else
    choice=0
fi

# Prometheus предоставляет различные метрики с базовыми типами, как
# Counter, Gauge, Histogram, Summary.
# тип "Gauge" лучше всего использовать для метрик,
# которые могут увеличиваться и уменьшаться в зависимости от нагрузки на систему.
# Подробнее о них тут
# https://www.tigera.io/learn/guides/prometheus-monitoring/prometheus-metrics/
# или тут
# https://prometheus-io.translate.goog/docs/concepts/metric_types/?_x_tr_sl=auto&_x_tr_tl=ru&_x_tr_hl=ru#histogram    
# В задании указано выведение базовых метрик ЦПУ, оперативная память, жесткий диск (объем))
# Для их вывода будет будет достаточно метрики Gauge
# (https://prometheus.io/docs/concepts/metric_types/#gauge)
# Вот шаблон вставки который должен быть
#
#   # HELP ${Par_Name} ${Par_Description}
#   # TYPE ${Par_Name} gauge
#   ${Par_Name}{${var}=${val1}} ${Par_Value1}
#   ${Par_Name}{${var}=${val2}} ${Par_Value2}
#
# Больше информации тут:
# https://linuxera.org/prometheus-metrics-on-your-applications/
#
# Фрагмент {${var}=${val}} - является не обязательным
# Подробнее см ТУТ (!!!): https://www.timescale.com/blog/four-types-prometheus-metrics-to-collect/ 

function stat_gauge(){
    # 1 - output,  2 - Par_Name, 3 - Par_Description, 4 - Par_Value1, 5 - var, 6 - val1, ...
    echo -en "$L_BRA# HELP ${2} ${3}$R_BRA\n" >> $1
    echo -en "$L_BRA# TYPE ${2} gauge$R_BRA\n" >> $1
    line=${2}
    if [[ ( ! -z $5 ) && ( ! -z $6 ) ]]; then
        line="${line}{${5}=\"${6}\"}"; fi
    echo -en "$L_BRA${line} ${4}$R_BRA\n" >> $1
    idx=3 # Начинаем цикл обработки дополнительных параметров
    while [[ -n ${@:4+idx:1} && -n ${@:5+idx:1} && -n ${@:6+idx:1} ]]; do
        echo -en "$L_BRA${2}{${@:5+idx:1}=\"${@:6+idx:1}\"} ${@:4+idx:1}$R_BRA\n" >> $1
        ((idx+=3))
    done
    # echo -en "<br></br>" >> $1
}

if [ $# != 0 ]; then # не должно быть входных аргументов
    echo -e $LYELLOW"Скрипт работает без параметров. Любые параметры игнорируются."$DEF
fi

echo -e $LMAGENTA"Сейчас данные пишутся в файл '${FILE}'. Чтоб остановить нажмите [Ctrl+C]"$DEF

if [ -e $FILE ]; then
    rm $FILE 
fi

while true; do
    touch $FILE # создаем файл 
    # сбор метрик
    cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')    
    mem=$(top -bn1 | grep "Mem :" | awk '{print $6}')
    spc=$(df / -BM | grep "/" | awk '{print $4}' | awk -F"M" '{print $1}') # сбор метрики (свободного места на диске)    
    space_total=$(df / -BM | grep "/" |awk '{print $2}'| awk -F"M" '{print $1}') # общ объем
    spc_used=$((space_total-spc))
  
    # печать метрик с переменным числом аргументов
    if [ $choice -eq 1 ]; then echo -en "$LDECBRA\n" >> $FILE ; fi

    stat_gauge $FILE "cpu__info" "CPU usage (in percentage)" $cpu
    stat_gauge $FILE "mem__info" "MEM is available RAM (Mb)" $mem "type" "free"
    stat_gauge $FILE "disk_info" "This is info about disk space (Mb)" $spc "type" "free" $spc_used "type" "used"
    
    if [ $choice -eq 1 ]; then echo -en "$RDECBRA\n" >> $FILE ; fi
    sleep 3
    rm $FILE
done
