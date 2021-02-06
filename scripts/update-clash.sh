#!/bin/ash

. /opt/acg/files/acg-cfg

geoip(){
  if [ "${GEOIP_MIRROR}" == 'aliyun' ]; then
    geoip_db_url="http://www.ideame.top/mmdb/Country.mmdb"
    geoip_version_url="http://www.ideame.top/mmdb/version"
  else
    geoip_db_url="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"
    geoip_version_url="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/version"
  fi
  remote_geoip_version=$(curl -s ${geoip_version_url})
  local_geoip_version=19700101
  geoip_version_file="${CLASH_PATH}/version_geoip"
  geoip_db_file="${CLASH_PATH}/Country.mmdb"
  [ -f "${geoip_version_file}" ] && local_geoip_version=$(cat "${geoip_version_file}")
  [ ! -f "${geoip_db_file}" ] && local_geoip_version=19700101
  if [ $(date -d "${local_geoip_version}0000" +%s) -lt $(date -d "${remote_geoip_version}0000" +%s) ]; then
    if [ -f ${geoip_db_file} ]; then
      echo "Updating geoip database from ${geoip_db_url}..."
      rm "${geoip_db_file}"
    else
      echo "Downloading geoip database from ${geoip_db_url}..."
    fi
    curl -L -#  -o "${geoip_db_file}" "${geoip_db_url}"
    if [ $? != 0 ] ; then
      echo "Failed to download geoip database."
      exit 1
    fi
    echo ${remote_geoip_version} > ${geoip_version_file}
    exit 0
  else
    echo "GeoIP database is up to date."
    exit 2
  fi
}

config(){
  if [ -z ${CLASH_CONFIG_URL} ]; then
    echo "Please set CLASH_CONFIG_URL first!"
    exit 1
  fi

  clash_config_file="${CLASH_PATH}/config.yaml"
  echo "Download Clash configuration ..."
  curl -L -# -o "${clash_config_file}.tmp" ${CLASH_CONFIG_URL}
  if [ $? -eq 0 ]; then
    if cmp -s "${clash_config_file}" "${clash_config_file}.tmp" ; then
      echo "Current Clash configuration is up to date."
      rm "${clash_config_file}.tmp"
      exit 2
    else
      [ -f "${clash_config_file}" ] && mv "${clash_config_file}" "${clash_config_file}.old"
      mv "${clash_config_file}.tmp" "${clash_config_file}"
      echo "Clash configuration has been updated."
      exit 0
    fi
  fi
  echo "Failed to download Clash configuration from ${CLASH_CONFIG_URL}. Please check your settings."
  exit 1

}

clash(){
  clash_bin="${CLASH_PATH}/clash"
  clash_version_file="${CLASH_PATH}/version_clash"
  if [ ! -f "${clash_bin}" ]; then
    echo "1970.01.01" > ${clash_version_file}
  fi
  if [ ! -f "${clash_version_file}" ]; then
    echo $(${clash_bin} -v 2>/dev/null | awk '{print $2}') > ${clash_version_file}
  fi
  local_clash_version=$(cat "${clash_version_file}")

  #date -d "${local_clash_version}-00:00" +%s
  echo "Locale Clash Premium: ${local_clash_version}."
  # echo "Please download the latest version from https://github.com/Dreamacro/clash/releases/tag/premium manually."

  [ -f /tmp/clash_premium_release.json ] && rm /tmp/clash_premium_release.json
  curl -s -o /tmp/clash_premium_release.json https://api.github.com/repos/Dreamacro/clash/releases/tags/premium
  if [ ! -f /tmp/clash_premium_release.json ]; then
    echo "Failed to get the release information of Clash Premium."
    exit 1
  fi
  remote_clash_version=$(jq '.name' /tmp/clash_premium_release.json | tr -d '"' | awk '{print $2}')
  if [ $(date -d "${local_clash_version}-00:00" +%s) -ge $(date -d "${remote_clash_version}-00:00" +%s)  ]; then
    echo "Clash Premium ${local_clash_version} is up to date."
    exit 2
  else
    echo "Found a new version of Clash Premium ${remote_clash_version}."
  fi

  [ -f /tmp/clash_premium_release_assets ] && rm /tmp/clash_premium_release_assets
  jq '.assets[].name' /tmp/clash_premium_release.json > /tmp/clash_premium_release_assets
  if [ ! -f /tmp/clash_premium_release_assets ]; then
    echo "Failed to get the release information of Clash Premium."
    rm /tmp/clash_premium_release.json
    exit 1
  fi
  i=0
  while read line ; do
    l=$(echo $line | grep "linux-${CLASH_BIN_ARCH}")
    if [[ ! -z $l ]]; then
      break
    fi
    i=$(( i+1 ))
  done < /tmp/clash_premium_release_assets
  rm /tmp/clash_premium_release_assets
  remote_clash_download_url=$(jq ".assets[${i}].browser_download_url" /tmp/clash_premium_release.json | tr -d '"')
  rm /tmp/clash_premium_release.json 
  echo "Start downloading Clash Premium ${remote_clash_version} from ${remote_clash_download_url}..."
  [ -f "${CLASH_PATH}/clash.gz" ] && rm "${CLASH_PATH}/clash.gz"
  curl -L -# -o "${CLASH_PATH}/clash.gz" "${remote_clash_download_url}"
  if [ ! -f "${CLASH_PATH}/clash.gz" ]; then
    echo "Failed to download Clash Premium."
    echo "Please download and upload it to ${CLASH_PATH} manually."
    exit 1
  fi
  [ -f ${CLASH_PATH}/clash.old ] && rm ${CLASH_PATH}/clash.old
  [ -f ${clash_bin} ] && mv ${clash_bin} ${CLASH_PATH}/clash.old
  gzip -d "${CLASH_PATH}/clash.gz" && chmod +x ${clash_bin} && ${clash_bin} -v
  if [ $? -eq 1 ]; then
    echo "Failed to download Clash Premium."
    echo "Please try to re-run this script to download it again."
    [ -f ${CLASH_PATH}/clash.gz ] && rm "${CLASH_PATH}/clash.gz"
    [ -f ${clash_bin} ] && rm ${clash_bin}
    mv ${CLASH_PATH}/clash.old ${clash_bin}
    exit 1
  fi
  new_clash_version=$(${clash_bin} -v 2>/dev/null | awk '{print $2}')

  echo ${new_clash_version} > ${clash_version_file}
  echo "Clash Premium has been updated to ${new_clash_version}."
  
}

if [ ! -d "${CLASH_PATH}" ]; then
  mkdir -p "${CLASH_PATH}"
fi

case "$1" in

geoip)
        geoip
    ;;
clash)
        clash
    ;;
config)
        config
    ;;

esac

exit 0