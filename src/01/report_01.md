## Для работы / проверки проекта можно принять во внимание следующее:

# 1. Что имеем:
   **1.1.** Хост-машина: Linux 6.5.0-14-generic #14~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Mon Nov 20 18:15:30 UTC 2 x86_64 x86_64 x86_64 GNU/Linux \
   **1.2.** VirtualBox Версия 7.0.12 r159484 (Qt5.15.3) \
   **1.3.** Установлена виртуальная машина (ВМ): Linux ws1 5.4.0-159-generic #173-Ubuntu SMP x86_64 (серверная без графики) \
   **1.4.** В ХМ есть папка `/home/felisasi/Documents/DO4_LinuxMonitoring_v2.0-1` к которой хотелось бы иметь доступ в виртуальной машине как shared folder \
   **1.5.** На машинах есть `openssh`, иначе устанавливаем \
   ```
   sudo apt install openssh
   ```

# 2. Настройка ВМ в VirtualBox:
   **2.1.** в разделе "Общие папки" добавлено: \
        путь: `/home/felisasi/Documents/DO4_LinuxMonitoring_v2.0-1` \
        доступ: `полный` \
        авто-подключение: `да` \
        в точке: `/mnt/` \
    **2.2.** Сеть - `Адаптер1` \
        Вкл.сетевой адаптер: `да` \
        Тип подключения: `NAT` \
        Подключить кабель: `да` \
        Нажимаем "Проброс портов", там добавляем правило: \
        Имя: `Rule 1` (автоматическое) \
        Протокол: `TCP` \
        Адрес хоста: (оставляем пустым) \
        Порт хоста: `12345` \
        Адрес гостя: (оставляем пустым) \
        Порт гостя: `22`

# 3. Подкючение к ВМ через терминал ХМ:
```bash
ssh -p 12345 felisasi@127.0.0.1
```

Если подключение впервые то можно увидеть сообщение такого вида:
```
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
    Someone could be eavesdropping on you right now man-in-the-middle attack)!
    It is also possible that a host key has just been changed.
    The fingerprint for the ED25519 key sent by the remote host is
    SHA256:BfcJa3V5jSxsBYhSMPR4YIsSm5uo2MIuoQgRNjCnu84.
    Please contact your system administrator.
    Add correct host key in /home/felisasi/.ssh/known_hosts to get id of this message.
    Offending ECDSA key in /home/felisasi/.ssh/known_hosts:3
    remove with:
    ssh-keygen -f "/home/felisasi/.ssh/known_hosts" -R "[127.0.0.1]12345"
    Host key for [127.0.0.1]:12345 has changed and you have equested strict checking.
    Host key verification failed.
```
Применим прделоженное решение

```bash 
ssh-keygen -f "/home/felisasi/.ssh/known_hosts" -R "[127.0.0.1]:12345"
```
на что будет содержащее сообщение
```bash
/home/felisasi/.ssh/known_hosts updated.
Original contents retained as /home/felisasi/.ssh/known_hosts.old
```

Пробуем вновь подключиться, отвечая на вопрос: \
`Are you sure you want to continue connecting (yes/no/[fingerprint])? yes` \
Если все прошло успешно, то будет предложено ввести пароль от пользователя на машине.

# 4. Настройка общей папки (в продолжение п.2.)
   * Виртуальная машина должна быть запущена.
   * В меню VirtualBox выберите вашу виртуальную машину.
   * Нажмите на "Устройства" (Devices) в верхнем меню виртуальной машины.
   * Выберите "Вставить образ дополнений гостевой ОС" (Insert Guest Additions CD image).
   * После этого в гостевой машине автоматически должно запуститься окно с предложением установить дополнения гостевой ОС. Выполните инструкции на экране для завершения установки.

   Если автоматическая установка не началась, вы можете открыть терминал в гостевой машине и выполнить следующие команды:
```bash
sudo apt update
sudo apt install build-essential dkms linux-headers-$(uname -r)
```
   команду для монтирования образа дополнений гостевой ОС:
```bash
sudo mount /dev/cdrom /media/cdrom
```
Затем перейдите в каталог с монтированным образом и выполните установку:
```bash
cd /media/cdrom
sudo ./VBoxLinuxAdditions.run
```
* После установки дополнений гостевой ОС перезагрузите виртуальную машину.
* Смонтированная папка должна быть в `cd /mnt`
