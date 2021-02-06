#!/bin/ash
acg_path="/opt/acg"

git --version 1>/dev/null 2>/dev/null
if [ $? != 0 ]; then
  apk add --update git
fi

git clone -b main https://github.com/yangliu/alpine-clash-gateway.git "${acg_path}"
chmod +x "${acg_path}/scripts/acg.sh"
${acg_path}/scripts/acg.sh install

