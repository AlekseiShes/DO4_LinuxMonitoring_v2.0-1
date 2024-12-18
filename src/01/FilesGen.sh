#!/bin/bash

curfolder=$1 # - папка для файлов
filecount=$2 # - количество файлов в каждой созданной папке.
filechars=$3 # - список букв в имени файла и расширении (7 для имени, не более 3  для расширения).
size=$4      # - размер файлов (в килобайтах).   
logfilename=$5 # путь файл для лог-файла
memlimit=$6  # - лимит доступной памяти (кБ)
uuid=$7      # - uuid

if ((filecount < 0)); then                       # если число файлов задано отрицательным, то это значит
    filecount=$(shuf -i 1-$((-filecount)) -n 1)  # нужно рандомное число файлов от 1 до модуля числа
fi
date=$(date +'%d%m%y')                           # дата в формате ДДММГГ
currentPrefix=$(echo $filechars | cut -d'.' -f1) #  подстрока с названием файла (возможные символы)
countLettersInOriginPrefix=$(echo $currentPrefix | wc -m) #  Кол-во допустимых символов в названии
counterOfletterPrefix=1                          #  Счётчик положения вставки новой буквы в названии
counterOfStepPrefix=2                            #  Шаг предыдущего счётчика
cyclePreffix=1                                   #  счётчик цикла, когда будут вставлены все возможные буквы, и нужно начинать сначала

currentSuffix=$(echo $filechars | cut -d'.' -f2) #  подстрока с расширением файла (возможные символы)
countLettersInOriginSuffix=$(echo $currentSuffix | wc -m) #  Кол-во допустимых символов в расширении
counterOfletterSuffix=1                          #  Счётчик положения вставки новой буквы в расширении
counterOfStepSuffix=2                            #  Шаг предыдущего счётчика
cycleSuffix=1                                    #  счётчик цикла, когда будут вставлены все возможные буквы, и нужно начинать сначала

counterOfCreatedFiles=0                          #  счётчик созданных файлов

# количество памяти которую можно засорять
avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))

while (( counterOfCreatedFiles < filecount && avail > 0 )); do # пока создано меньше чем нужно файлов или еще есть место 
    if [[ ! $(echo $currentPrefix | wc -m) -lt 5 ]]; then #  проверка, чтобы в названии было не меньше 4 символов
    #     let cyclePreffix+=0
    # else
        CurName_NewFile="$curfolder/$currentPrefix"_"$date.$currentSuffix"
        if [ ! -e $CurName_NewFile ]; then
            $(touch $CurName_NewFile 2>/dev/null)
            $(fallocate -l $size"Kib" $CurName_NewFile 2>/dev/null) # коректировка размера файла
            if ((size<1000)); then tab="\t"; else tab=""; fi        # дополнителдьный таб для симметрии в лог файле
            avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
            if [ -f $CurName_NewFile ]; then                        #  Если файл создался, записываем в логфайл
                echo -e "$(date +"%d-%m-%Y")\t$(date +"%H:%M:%S:%3N")\t${avail}\t${size}${tab}\tFILE\t$uuid\t$CurName_NewFile" >>$logfilename # Добавление записи в лог-файл
            fi
        fi
        avail=$(( $(df / -Bk --output=avail | grep "K" | grep -o '[0-9]' | tr -d '\n') - memlimit ))
        let counterOfCreatedFiles+=1
    fi

    reName currentPrefix cyclePreffix counterOfletterPrefix counterOfStepPrefix countLettersInOriginPrefix
    let cyclePreffix+=1 #  так как поставили букву, увел. счётчик цикла
    reName currentSuffix cycleSuffix counterOfletterSuffix counterOfStepSuffix countLettersInOriginSuffix
    let cycleSuffix+=1 #  так как поставили букву, увел. счётчик цикла

done

echo $avail
