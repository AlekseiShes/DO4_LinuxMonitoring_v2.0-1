#!/bin/bash

# bash 02/main.sh rdxtfc klmno.qwe 2Mb
regim_debug=0 # 0 - режим по задании (100 папок), 1 <= k - режим отладки (k папок)
fieldflood="" # по умолчанию флуд в корне

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

# if ((regim_debug>0));then 
#     fieldflood=$(readlink -m "$path/../..")
# fi

oldcount_files=$(find $fieldflood/ -type f | wc -l )  # old count files 
oldcount_folders=$(find $fieldflood/ -type d | wc -l ) # old count files 


begin_script_sec=$(date +"%s%3N") # запись времени начала скрипта
begin_script_time=$(date +"%H:%M:%S")

folderchars=$1 # список букв для названии папок
filechars=$2   # список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
filesize=$3    # размер файлов (в Mb).

# Проверяем кол-во и качество входных параметров
if [ "$#" -eq 1 ] && [[ "$1" =~ ^(--help|-h)$ ]]; then
    echo "# - тип_образец  - описание"
    echo "1 - string_AaZz  - список букв английского алфавита, используемый в названии папок (до 7 знаков)."
    echo "2 - string_AaZz  - список букв английского алфавита, используемый в имени файла и расширении"
    echo "    (до 7 знаков для имени, не более 3 знаков для расширения)."
    echo "3 - unsigned int - размер файлов (в мегабайтах, до 100Mb)."
    exit 0
elif [ $# -ne 3 ]; then # проверка на кол-во параметров
    echo "Ожидается 3 параметра, а введено" $#
    help_h 2 # 2 - код ошибки о не хватке параметров
elif [[ ! ($folderchars =~ ^[A-Za-z]+$ && $(echo $folderchars | wc -m) -le 8) ]]; then
    echo "Первый параметр "$folderchars" может содержать только английские символы до 7 шт!"
    help_h 1
elif [[ ! ($filechars =~ ^[A-Za-z]+(\.)[A-Za-z]+$ &&
        $(echo $filechars | cut -d'.' -f1 | wc -m) -le 8 &&
        $(echo $filechars | cut -d'.' -f2 | wc -m) -le 4) ]]; then
    echo "Второй параметр "$filechars" может содержать только английские символы, разделенные точкой!"
    echo " (до 7 символов на имя до точки и 3 на расширение после точки)!"
    help_h 1 
elif [[ ! $filesize =~ ^[1-9][0-9]?(Mb)$|^100(Mb)$ ]]; then
    echo "Третий параметр должен быть беззнаковым целым до 100Mb (c указанием суффикса Mb)!"
    help_h 1
else
    size=$(( $(echo "$filesize" | grep -o '[0-9]' | tr -d '\n') *1024 ))  #  размер файла(просто число) пересчитано в кб
    date=$(date +'%d%m%y')      # дата в формате ДДММГГ_ЧЧММССмкс _%H_%M_%S_%3N
    logfilename=$path"/logfile_"$date".log" #  Создание имени log-файла
    # ограничение (кБ) на допустимый остаток памяти 
    memlimit=1048576 # (1Гб=1024*1024)
    limitfolder=100  # ограничения числа папок
    # если режим дебага, то повышаем лимит до уровня, чтоб хватило заолнить 1 папку и на еще 1 файл
    if ((regim_debug>0));then
        memlimit=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - $(shuf -i 1-$limitfolder -n 1) * size ))
        limitfolder=$regim_debug
    fi

    countDir=0                  # Кол-во созданных директорий
    for currentDir in $fieldflood/* ; do   # текущая директория из ...
        if ((avail<0 || countDir >= limitfolder)); then # прерывание если уже создано больше 100 папок
            break               # прерывание в случае замершении памяти
        fi
        
        if [ ! -d $currentDir ]  || { [ $currentDir = '/bin' ] || [ $currentDir = '/sbin' ]; }; then
            # echo "passed currentDir="$currentDir
            continue            # пропускаем исключающие директории
        fi

        # далее вызов скрипта
        foldercount=$(shuf -i 1-$((limitfolder-countDir)) -n 1) #
        filecount=-15          # число файлов знак минус означает рандомность величины от 1 (вкл) до 15 (вкл)
        avail=$(source "${path}/FoldersGen.sh" $currentDir $foldercount $folderchars $filecount $filechars $size $logfilename $memlimit $path)
            #  $currentDir \   # 1 - это абсолютный путь (для флуда)
            #  $foldercount \  # 2 - количество вложенных папок.
            #  $folderchars \  # 3 - список букв для названии папок.
            #  $filecount \    # 4 - количество файлов в каждой созданной папке.
            #  $filechars \    # 5 - список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
            #  $size \         # 6 - размер файлов (в килобайтах).   
            #  $logfilename \  # 7 - путь файл для лог-файла
            #  $memlimit \     # 8 - лимит доступной памяти (кБ)
            #  $path)          # 9 - путь к скрипту
        let countDir+=foldercount
    done

    # все равно пересчитаем, чтоб исключить некорректные данные
    avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
    if ((avail<0)); then
        echo "The process was interrupted:"
        echo "   free space=$(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n')"
        echo "   is less than the set limit="$memlimit
    else
        echo "Successful done!"
    fi

    end_script_sec=$(date +"%s%3N") # запись времени конца скрипта
    end_script_time=$(date +"%H:%M:%S")

    # Conclusion
    echo "In difectory $fieldflood/ was created:"
    echo "    folders = $(( $(find $fieldflood/ -type d | wc -l ) - oldcount_folders)) (в том числе дополнительные созданные системой)"
    echo "    files   = $(( $(find $fieldflood/ -type f | wc -l ) - oldcount_files))  (в том числе дополнительные, созданные системой)"
    echo "NB! Если папки или файлы с такими же именами созданы, то повторно они не создаются!"
fi

sec=$(( ($end_script_sec - $begin_script_sec)/1000 ))
    
#  вывод времени работы скрипта
echo "Script begin time = $begin_script_time"
echo "Script end time = $end_script_time"
echo "Script execution time (in seconds) = $sec"
