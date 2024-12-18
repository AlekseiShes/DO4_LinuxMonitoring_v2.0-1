#!/bin/bash

# Данный скрипт запускаем на локальной машине
# на которой будем запускать скприпты по флуду папок
# уточните архитектуру своей машины командой 'dpkg --print-architecture'

# sudo bash 07/main.sh
# ВНИМАНИЕ для корректности работы скрипта запускайте его под sudo

# !!!!!!!!!!!!!!  A вообще лучше выполнить построчно ручками  !!!!!!!!!!!!!!

cd /tmp
mkdir linux_monitoring_v2
cd linux_monitoring_v2 # далее сидим в этой папке

# prometheus: скачиваем и устанавливаем последнюю версию из https://prometheus.io/download/ 
# уточните архитектуру своей машины командой 'dpkg --print-architecture'
apt install wget -y
wget https://github.com/prometheus/prometheus/releases/download/v2.49.0-rc.2/prometheus-2.49.0-rc.2.linux-amd64.tar.gz
tar xvf prometheus-2.49.0-rc.2.linux-amd64.tar.gz # распоковываем
mkdir /opt/prometheus
cp prometheus-2.49.0-rc.2.linux-amd64 /opt/prometheus -r # переносим папку в 
chmod +x /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/prometheus # даем права на исполнение
ln -s /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/prometheus /usr/local/bin/
ln -s /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/promtool /usr/local/bin/ 
# командой выше в ../bin делаем мягкую ссылку на бинарник
rm -rf prometheus-2.49.0-rc.2.linux-amd64*  # удаляем скаченный архив  и папку которую уже копирнули ранее

# prometheus: настройки
mkdir /etc/prometheus
tee <<EOF >/dev/null /etc/prometheus/prometheus.yml
global:
  scrape_interval:     1s # то, как часто Прометей будет очищать цели.
  #evaluation_interval: 1s # то, как часто Prometheus будет оценивать правила.

#rule_files:
#  # - "first.rules"
#  # - "second.rules"

scrape_configs:
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 1s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    scrape_interval: 1s
    static_configs:
      - targets: ['localhost:9100']
EOF
# cp /etc/prometheus/prometheus.yml /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/ # можно пропустить

useradd --no-create-home --shell /bin/false prometheus
mkdir /var/lib/prometheus/
# read more: https://github.com/systemd/systemd/issues/21862
SYSTEMD_EDITOR=tee systemctl edit --full --force prometheus.service <<EOF 
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/consoles \
--web.console.libraries=/opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/console_libraries \
[Install]
WantedBy=multi-user.target
EOF
chown prometheus:prometheus /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/prometheus
chmod +x /opt/prometheus/prometheus-2.49.0-rc.2.linux-amd64/prometheus
chown -R prometheus:prometheus /opt/prometheus/
chown -R prometheus:prometheus /var/lib/prometheus/
systemctl daemon-reload && systemctl enable prometheus && systemctl restart prometheus

# Экспортер: скачиваем сжатый пакет и устанавливаем последнюю версию из https://github.com/prometheus/node_exporter/releases 
# уточните архитектуру своей машины командой 'dpkg --print-architecture'
cd /tmp/linux_monitoring_v2 # возвращаемся в папку тмп или убеждаемся что в ней. 
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvf node_exporter-1.7.0.linux-amd64.tar.gz # распоковываем
mkdir /opt/node_exporter
cp node_exporter-1.7.0.linux-amd64 /opt/node_exporter -r # переносим папку в 
chmod +x /opt/node_exporter/node_exporter-1.7.0.linux-amd64/node_exporter # даем права на исполнение
ln -s /opt/node_exporter/node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/ 
# командой выше в ../bin делаем мягкую ссылку на бинарник
rm -rf node_exporter-1.7.0.linux-amd64* # удаляем скаченный архив  и папку которую уже копирнули ранее

# Экспортер: настраиваем
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter
chown node_exporter:node_exporter /opt/node_exporter/node_exporter-1.7.0.linux-amd64/node_exporter
chown -R node_exporter:node_exporter /opt/node_exporter
chmod +x /opt/node_exporter/node_exporter-1.7.0.linux-amd64
chmod +x /opt/node_exporter/

tee <<EOF >/dev/null /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target 
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF
# Экспортер: включаем и делаем рестарт
sudo systemctl daemon-reload && sudo systemctl enable node_exporter && sudo systemctl restart node_exporter
# if status error https://jaanhio.me/blog/linux-node-exporter-setup/

# еси мы в терминале машины, то после изменений конфиг файлов следует делать такие команды
# systemctl daemon-reload 
# systemctl enable node_exporter
# systemctl restart node_exporter
# systemctl enable prometheus
# systemctl restart prometheus

# и записать в файл статусы служб
# echo -e "$(systemctl status prometheus)" >status_prometheus 
# echo -e $(systemctl status node_exporter) >status_node_exporter

# проверить метрики в ВМ
#echo -e "$(curl localhost:9100/metrics)" > curl_localhost_9100_metrics
#echo -e "$(curl localhost:9090/metrics)" > curl_localhost_9090_metrics

# https://losst.pro/ustanovka-i-nastrojka-prometheus#shag-9-dobavlenie-node-exporter-v-prometheus полдезно


# подключение порта 9096 хост машины к порту 9090 локальной машины
# ssh -L 9096:localhost:9090 -p 12345 felisasi@127.0.0.1 # так подключаем 

# проверить метрики в ХМ
#echo -e "$(curl localhost:9096/metrics)" > curl_localhost_9096_metrics
