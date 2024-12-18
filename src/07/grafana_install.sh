#!/bin/bash

# Данный скрипт запускаем на хост машине
# на которой будем запускать Графану
# уточните архитектуру своей машины командой 'dpkg --print-architecture'

# ВНИМАНИЕ для корректности работы скрипта запускайте его под sudo

# !!!!!!!!!!!!!!  A вообще лучше выполнить построчно ручками  !!!!!!!!!!!!!!

cd /tmp
mkdir linux_monitoring_v2


# Графана: скачиваем сжатый пакет и устанавливаем последнюю версию из https://grafana.com/grafana/download
# уточните архитектуру своей машины командой 'dpkg --print-architecture'
cd /tmp/linux_monitoring_v2 # возвращаемся в папку тмп или убеждаемся что в ней. 
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-10.2.3.linux-amd64.tar.gz
  # выдал ошибку
      # --2024-01-10 13:29:18--  https://dl.grafana.com/enterprise/release/grafana-enterprise-10.2.3.linux-amd64.tar.gz
      # Resolving dl.grafana.com (dl.grafana.com)... 151.101.246.217, 2a04:4e42:3a::729
      # Connecting to dl.grafana.com (dl.grafana.com)|151.101.246.217|:443... connected.
      # HTTP request sent, awaiting response... 451 geofence:blocked
      # 2024-01-10 13:29:19 ERROR 451: geofence:blocked.
  # Если применить snap install grafana
  # То после установки будет ответ: grafana 6.7.4 from Canonical✓ installed
  # Но я скачал tar.gz файл через ВПН и далее по инструкция ниже
  tar xvf grafana-enterprise-10.2.3.linux-amd64.tar.gz # распоковываем
  mkdir /opt/grafana
  cp grafana-v10.2.3 /opt/grafana -r # переносим папку в 
  chmod +x /opt/grafana/grafana-v10.2.3/bin/* # даем права на исполнение всем бинарникам 
  # а именно таким файлам как grafana grafana-cli grafana-server
  ln -s /opt/grafana/grafana-v10.2.3/bin/grafana /usr/local/bin/ 
  ln -s /opt/grafana/grafana-v10.2.3/bin/grafana-cli /usr/local/bin/ 
  ln -s /opt/grafana/grafana-v10.2.3/bin/grafana-server /usr/local/bin/ 
  # командой выше в ../bin делаем мягкую ссылку на бинарники
  rm -rf grafana* # удаляем скаченный архив  и папку которую уже копирнули ранее

# далее ряд команд из памяти терминала:
# systemctl start grafana-server
# find /opt/grafana/ | grep service
# cp /opt/grafana/grafana-v10.2.3/packaging/deb/systemd/grafana-server.service /etc/systemd/system/
# ll /etc/systemd/system/
# vim /etc/systemd/system/grafana-server.service 
# ll /tmp/linux_monitoring_v2/grafana-v10.2.3/packaging/wrappers/
# ll /opt/grafana/grafana-v10.2.3/
# ll /opt/grafana/grafana-v10.2.3/conf/defaults.ini 
# cp /opt/grafana/grafana-v10.2.3/conf/defaults.ini /opt/grafana/grafana-v10.2.3/conf/grafana.ini
# vim /opt/grafana/grafana-v10.2.3/conf/grafana.ini
# mkdir /opt/grafana/grafana-v10.2.3/data
# systemctl daemon-reload
# systemctl restart grafana-server.service 
# systemctl status grafana-server.service 
#  journalctl -u grafana-server.service 

# oot@ws1:/tmp/linux_monitoring_v2# rm /etc/systemd/system/grafana-server.service 
# root@ws1:/tmp/linux_monitoring_v2# systemctl daemon-reload 
# root@ws1:/tmp/linux_monitoring_v2# systemctl restart grafana-server.service 
# root@ws1:/tmp/linux_monitoring_v2# systemctl status grafana-server.service 
# графена http://localhost:3000/d/N_NXr9KSz/new-dashboard-copy-10012024?orgId=1&refresh=5s admin admin

# прометей тут http://localhost:9090/targets?search=
# экспортер http://localhost:9100/metrics
