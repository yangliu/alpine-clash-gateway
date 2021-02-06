#!/bin/ash
acg_path="/opt/acg"

wget -O /tmp/acg.zip https://github.com/yangliu/alpine-clash-gateway/archive/main.zip
unzip /tmp/acg.zip -d /tmp
mv /tmp/alpine-clash-gateway-main "${acg_path}"
chmod +x "${acg_path}/scripts/acg.sh"
${acg_path}/scripts/acg.sh install

