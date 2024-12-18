#!/bin/bash

function reName() { #переименование
    # 1-5 аргументы возвращаемые величины
    local -n curr=$1 cycl=$2 cLett=$3 cStep=$4 # так можно получить УКАЗАТЕЛЬ на входные переменные
    temp="${curr:0:cLett}"                    #  Подстрока до вставки новой буквы
    curr="$temp${temp:length-1}${curr:cLett}" #  Вставка новой буквы и конкатенация со второй подстрокой
    let cLett+=$cStep
    if [[ $cycl -eq $5 ]]; then
        cLett=$cStep
        let cStep+=1
        cycl=1
    fi
    #  при постановке буквы, увел. счётчик цикла cycl осуществляется СНАРУЖИ : let cycl+=1 
}

path4fill=$1   # это абсолютный путь.
foldercount=$2 # количество вложенных папок.
folderchars=$3 # список букв для названии папок.
filecount=$4   # количество файлов в каждой созданной папке.
filechars=$5   # список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
size=$6        # размер файлов (в килобайтах).   
logfilename=$7 # путь файл для лог-файла
memlimit=$8    # лимит доступной памяти (кБ)
path=$9        # путь к скрипту

if ((foldercount < 0)); then                        # если число папок задано отрицательным, то это значит
    foldercount=$(shuf -i 1-$((-foldercount)) -n 1) # нужно рандомное число папок от 1 до модуля числа
fi
foldercharscount=$(echo $folderchars | wc -m);  #  Кол-во допустимых символов в названии папки
date=$(date +'%d%m%y')                          # дата в формате ДДММГГ

if [[ ! -e $logfilename ]]; then
    $(touch $logfilename)                       #  Создание log-файла
    if [[ -e $logfilename && ! -s $logfilename ]]; then #  Если лог-файл существует, то 
        echo -e "DATE\t\tTime\t\t\tAVAIL\tSIZE\tTYPE\tUUID\t\t\t\t\t\t\t\t\tPATH\n" \
        >> $logfilename;                        # добавляем шапочку в него
    fi
fi
currentName=$folderchars;                       #  Текущее название папки в цикле
counterOfletter=1;                              #  Счётчик положения вставки новой буквы в названии папки
counterOfStep=2;                                #  Шаг предыдущего счётчика
avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
uuid="$(sudo cat /sys/class/dmi/id/product_uuid 2>/dev/null)" # получаем uuid 
for (( i=0, j=1; i < $foldercount && $avail>0; i++, j++)); do  
    #  i - кол-во необходимых папок, j - контролирует цикл вставки всех букв по порядку
    if [[ $(echo $currentName | wc -m) -lt 5 ]]; then #  Если название папки меньше= четырёх
        let i-=1;                               #  то пропускаем его
    else
        curr_folder=$path4fill/$currentName"_"$date # текущая папка
        if [ ! -e $curr_folder ]; then 
            # если директория еще не существует, то создаем ее
            $(mkdir $curr_folder 2>/dev/null); #  Создание новой папки
            avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
            if [ -d $curr_folder ]; then         #  Если каталог создался, записываем в логфайл 
                echo -e "$(date +"%d-%m-%Y")\t$(date +"%H:%M:%S:%3N")\t$avail\t----\tDIR \t$uuid\t$curr_folder" \
                >> $logfilename;  # Добавление записи в лог-файл
            fi
        fi # если директория УЖЕ существует, то пропустим, в задании ничего не сказано про такие случаи
        avail=$(source "${path}/FilesGen.sh" $curr_folder $filecount $filechars $size $logfilename $memlimit $uuid)
            # $curr_folder # 1 - папка для файлов
            # $filecount   # 2 - количество файлов в каждой созданной папке.
            # $filechars   # 3 - список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
            # $size        # 4 - размер файлов (в килобайтах).   
            # $logfilename # 5 - путь файл для лог-файла
            # $memlimit    # 6 - лимит доступной памяти (кБ)
            # $uuid)       # 7 - id машины запускающей скрипт
    fi    
    reName currentName j counterOfletter counterOfStep foldercharscount
done

echo $avail

