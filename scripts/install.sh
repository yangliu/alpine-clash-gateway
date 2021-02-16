#!/bin/sh
ver="0.1.3"

if [ -z ${1} ]; then
  acg_path="/opt/acg"
else
  acg_path="${1}"
fi

# system detection
sys=$(uname -s)
if [[ "${sys}" != "Linux" ]]; then
  echo "Unsupport system (${sys}). ACG can only run on Linux."
  exit 1
fi

. /etc/os-release
if [[ "${NAME}" != "Alpine Linux" ]]; then
  echo "Only Alpine Linux is supported currently."
  exit 1
fi

# ACG install path
[ ! -d "${acg_path}" ] && mkdir -p "${acg_path}"

[ -f /tmp/acg.zip ] && rm /tmp/acg.zip
[ -d "/tmp/alpine-clash-gateway-${ver}" ] && rm -rf "/tmp/alpine-clash-gateway-${ver}"
wget -O /tmp/acg.zip "https://github.com/yangliu/alpine-clash-gateway/archive/${ver}.zip"
unzip /tmp/acg.zip -d /tmp
cp -R /tmp/alpine-clash-gateway-${ver}/* "${acg_path}/"
escaped_acg_path=$(printf '%s\n' "${acg_path}" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/acg"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/acg-httpd"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/scripts/clash-proxy"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" ${acg_path}/scripts/*.sh
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/www/cgi-bin/api"
chmod +x "${acg_path}/scripts/acg.sh"

# arch detection
uarch=$(uname -m)
case "${uarch}" in
  x86)      arch="386"
  ;;
  x86_64)   arch="amd64"
  ;;
  aarch64)  arch="armv8"
  ;;
  armhf)    arch="armv6"
  ;;
  armv7*)    arch="armv7"
  ;;
  armv6*)    arch="armv6"
  ;;
  armv5*)    arch="armv5"
  ;;
  *)        arch="${uarch}"
  ;;
esac
sed -i "s/CLASH_BIN_ARCH=.*$/CLASH_BIN_ARCH=${arch}/g" "${acg_path}/files/acg-cfg-sample"

# interface name
guess_in=$(ip route | grep default | awk -e {'print $5'})
sed -i "s/CLASH_INTERFACE_NAME=.*$/CLASH_INTERFACE_NAME=${guess_in}/g" "${acg_path}/files/acg-cfg-sample"

${acg_path}/scripts/acg.sh install
