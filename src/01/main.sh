#!/bin/bash

# bash 01/main.sh $(pwd)/temp 5 qwerty 4 abcdef.xyz 5kb
regim_debug=0 # 0 - режим по задании, 1 - режим отладки

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

# Тут мы обращаемся к функции которая сообщает какой тип у переменной 
# unsigned, int, float или в иных случаях string
# допускается ввод переменной в научной нотации ( -2.1e1 >> int)
getType(){
    source "$path"/getType.sh "$1"
}

path4fill=$(readlink -m $1)   # получаем полный путь
foldercount=$2 # количество папок
folderchars=$3 # список букв для названии папок
filecount=$4   # количество файлов
filechars=$5   # список букв для названии файла и расширения
filesize=$6    # размер файлов например: 3kb

# Проверяем кол-во и качество входных параметров
if [ "$#" -eq 1 ] && [[ "$1" =~ ^(--help|-h)$ ]]; then
    echo "# - тип_образец  - описание"
    echo "1 - string_Aa/Zz - это абсолютный путь."
    echo "2 - unsigned int - количество вложенных папок."
    echo "3 - string_AaZz  - список букв английского алфавита, используемый в названии папок (до 7 знаков)."
    echo "4 - unsigned int - количество файлов в каждой созданной папке."
    echo "5 - string_AaZz  - список букв английского алфавита, используемый в имени файла и расширении"
    echo "    (до 7 знаков для имени, не более 3 знаков для расширения)."
    echo "6 - unsigned int - размер файлов (в килобайтах, до 100)."
    exit 0
elif [ $# -ne 6 ]; then # проверка на кол-во параметров
    echo "Ожидается 6 параметров, а введено" $#
    help_h 2 # 2 - код ошибки о не хватке параметров
elif [[ ! -d $path4fill ]]; then
    echo "Первый параметр: не существует директория: "$1
    help_h 1 # 1 - код ошибки о не корректности параметров
elif [[ ! ${1: 0: 1} ==  $delimiter ]]; then
    echo "Первый параметр: указан не абсолютный путь: "$1
    help_h 1 # 1 - код ошибки о не корректности параметров
elif [[ ! "unsigned" == $(getType $foldercount) ]]; then
    echo "Второй параметр должен быть беззнаковым целым!"
    help_h 1 # 1 - код ошибки о не корректности параметров
elif [[ ! ($folderchars =~ ^[A-Za-z]+$ && $(echo $folderchars | wc -m) -le 8) ]]; then
    echo "Третий параметр "$folderchars" может содержать только английские символы!"
    help_h 1
elif [[ ! "unsigned" == $(getType $filecount) ]]; then
    echo "Четвертый параметр должен быть беззнаковым целым!"
    help_h 1
elif [[ ! ($filechars =~ ^[A-Za-z]+(\.)[A-Za-z]+$ &&
        $(echo $filechars | cut -d'.' -f1 | wc -m) -le 8 &&
        $(echo $filechars | cut -d'.' -f2 | wc -m) -le 4) ]]; then
    echo "Пятый параметр "$filechars" может содержать только английские символы, разделенные точкой!"
    echo " (до 7 символов на имя до точки и 3 на расширение после точки)!"
    help_h 1
elif [[ ! $filesize =~ ^[1-9][0-9]?(kb)$|^100(kb)$ ]]; then
    echo "Шестой параметр должен быть беззнаковым целым до 100kb (c указанием суффикса kb)!"
    help_h 1
else
    size=$(echo "$filesize" | grep -o '[0-9]' | tr -d '\n') # Размер файла(просто число)
    date=$(date +'%d%m%y')                                  # Дата в формате ДДММГГ
    logfilename=$path"/logfile_"$date".log"                 # Создание имени log-файла
    # ограничение (кБ) на допустимый остаток памяти 
    memlimit=1048576 # (1Гб=1024*1024) # по заданию
    # если режим дебага, то повышаем лимит до уровня, чтоб хватило заолнить 1 папку и на еще 1 файл
    if ((regim_debug>0));then
        memlimit=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - (filecount+1)*size ))
    fi
    oldcount_files=$(find $path4fill -type f | wc -l )      # старое число файлов
    oldcount_folders=$(find $path4fill -type d | wc -l )    # староечисло папок

    # далее вызов скрипта 
    avail=$(source "${path}/FoldersGen.sh" $path4fill $foldercount $folderchars $filecount $filechars $size $logfilename $memlimit $path)
        # $path4fill \    # 1 - это абсолютный путь (для флуда)
        # $foldercount \  # 2 - количество вложенных папок.
        # $folderchars \  # 3 - список букв для названии папок.
        # $filecount \    # 4 - количество файлов в каждой созданной папке.
        # $filechars \    # 5 - список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
        # $size \         # 6 - размер файлов (в килобайтах).   
        # $logfilename \  # 7 - путь файл для лог-файла
        # $memlimit \     # 8 - лимит доступной памяти (кБ)
        # $path)          # 9 - путь к скрипту
    
    # все равно пересчитаем, чтоб исключить некорректные данные
    avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
    if ((avail<0)); then # avail - количество свободной части памяти для флуда
        echo "The process was interrupted:" # Если достигли лимит, то досрочно прекрощаем флуд
        echo "   free space=$(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n')"
        echo "   is less than the set limit="$memlimit
    else
        echo "Successful done!" # Если не достигли потолка
    fi

    # Вывод результата работы скрипта
    echo "In difectory '${path4fill}' was created:"
    echo "    folders = $(( $(find $path4fill -type d | wc -l ) - oldcount_folders))"
    echo "    files   = $(( $(find $path4fill -type f | wc -l ) - oldcount_files))"
    echo "NB! Если папки или файлы с такими же именами созданы, то повторно они не создаются! Дополнительно создается лог-файл."
fi
