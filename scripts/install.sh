#!/bin/ash

git --version 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  apk add --update git
fi

git clone -b main https://github.com/yangliu/alpine-clash-gateway.git /opt/acg
chmod +x /opt/acg/scripts/acg.sh
/opt/acg/scripts/acg.sh install

