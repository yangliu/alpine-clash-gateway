#!/bin/sh
ver="0.1.4"

#wget -O - https://cdn.jsdelivr.net/gh/yangliu/alpine-clash-gateway@main/scripts/update.sh | sh -s /opt/acg
if [ -z ${1} ]; then
  acg_path="/opt/acg"
else
  acg_path="${1}"
fi

# load the old configuration
cfg_file="${acg_path}/files/acg-cfg"
if [ ! -f "${cfg_file}" ]; then
  echo "Cannot find ACG installation at ${acg_path}."
  exit 1
fi
. "${cfg_file}"

# download new acg and do basic setup
[ -f /tmp/acg.zip ] && rm /tmp/acg.zip
[ -d "/tmp/alpine-clash-gateway-${ver}" ] && rm -rf "/tmp/alpine-clash-gateway-${ver}"
wget -O /tmp/acg.zip "https://github.com/yangliu/alpine-clash-gateway/archive/${ver}.zip"
unzip /tmp/acg.zip -d /tmp
cp -R /tmp/alpine-clash-gateway-${ver}/* "${acg_path}/"
escaped_acg_path=$(printf '%s\n' "${acg_path}" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/acg"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/acg-httpd"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/files/adguardhome"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/scripts/clash-proxy"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/scripts/agh-proxy"
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" ${acg_path}/scripts/*.sh
sed -i "s/acg_path=\"\/opt\/acg\"/acg_path=\"${escaped_acg_path}\"/g" "${acg_path}/www/cgi-bin/api"

# update configuration file
set_acg_cfg(){
  grep "${1}=" "${cfg_file}" >/dev/null
  if [ $? -eq 0 ]; then
    ESCAPED_KEYWORD=$(printf '%s\n' "${2}" | sed -e 's/[]\/$*.^[]/\\&/g');
    sed -i "s/${1}=.*$/${1}=${ESCAPED_KEYWORD}/g" "${cfg_file}"
  fi
}
mv "${cfg_file}" "${cfg_file}.old"
cp "${acg_path}/files/acg-cfg-sample" "${cfg_file}"
while read -r line; do
  echo "${line}" | grep -e '%\s*#.*$' > /dev/null
  if [ $? -eq 0 ]; then
    break
  fi
  echo "${line}" | grep -e '.*=.*' > /dev/null
  if [ $? -eq 0 ]; then
    var_name=$(echo "${line}" | awk -F '=' '{print $1}')
    set_acg_cfg "${var_name}" "$(eval echo \${$var_name})"
  fi
done < "${cfg_file}"

echo "ACG has been updated. Please consider restarting ACG."
exit 0