#!/bin/sh

if [ -z ${1} ]; then
  acg_path="/opt/acg"
else
  acg_path="${1}"
fi

[ ! -d "${acg_path}" ] && mkdir -p "${acg_path}"

[ -f /tmp/acg.zip ] && rm /tmp/acg.zip
[ -d /tmp/alpine-clash-gateway-main ] && rm -rf /tmp/alpine-clash-gateway-main
wget -O /tmp/acg.zip https://github.com/yangliu/alpine-clash-gateway/archive/main.zip
unzip /tmp/acg.zip -d /tmp
cp -R /tmp/alpine-clash-gateway-main/* "${acg_path}/"
escaped_acg_path=$(printf '%s\n' "${acg_path}" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/acg"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/scripts/clash-proxy"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" ${acg_path}/scripts/*.sh
chmod +x "${acg_path}/scripts/acg.sh"
${acg_path}/scripts/acg.sh install
