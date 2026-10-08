#!/bin/bash

# Script to install Node exporter on linux/debian systems

cd /tmp/

NODE_EXPORTER_VERSION="1.7.0"
ARCH="amd64"
DISTRIBUTION="linux"

wget "https://artifactory.cloud.capitalone.com/artifactory/rpm-internalfacing/CloudMonitoring/node_exporter/node_exporter-$NODE_EXPORTER_VERSION.$DISTRIBUTION-$ARCH.tar.gz"

if [[ $? -ne 0 ]]; then
    echo "File download failed. Exiting the node exporter installation"
    exit 1;
fi

tar xfz node_exporter-$NODE_EXPORTER_VERSION.$DISTRIBUTION-$ARCH.tar.gz
cp node_exporter-$NODE_EXPORTER_VERSION.$DISTRIBUTION-$ARCH/node_exporter /usr/local/bin/

useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=node exporter
After=network.target
Wants=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

sleep 2
systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service

NODE_EXP_STATUS=`systemctl is-active node_exporter.service`

if [ ${NODE_EXP_STATUS} == "active" ]; then
    echo "Node Exporter installation successful and the service is active"
else
    echo "Node Exporter installation or start up failed"
fi