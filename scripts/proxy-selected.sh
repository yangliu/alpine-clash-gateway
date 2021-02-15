#!/bin/sh

acg_path="/opt/acg"

# Load Configuration
if [ -f "${acg_path}/files/acg-cfg" ]; then
  . "${acg_path}/files/acg-cfg"
else
  echo "The configuration file is missing. Please re-run the installation script."
  exit 1
fi
# Load Version
. "${acg_path}/files/version"

save(){
  curl -s \
  -o /tmp/clash_proxies.json \
  -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" \
  -H "Content-Type:application/json" \
  "http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT}/proxies"
  if [ $? -eq 0 ] && [ -f /tmp/clash_proxies.json ]; then
    [ -f /tmp/proxy-selected-tmp ] && rm /tmp/proxy-selected-tmp
    jq '.proxies | keys' /tmp/clash_proxies.json | 
    grep '".*"' | sed 's/^\s*"//g' | sed 's/,$//g' | sed 's/"$//g' |
    while IFS= read -r proxy_group; do
      proxy_group_escape="\"${proxy_group}\""
      proxy_group_type=$(jq -r ".proxies.${proxy_group_escape}.type" /tmp/clash_proxies.json)
      if [[ "${proxy_group_type}" == "Selector" ]]; then
        proxy_now=$(jq -r ".proxies.${proxy_group_escape}.now" /tmp/clash_proxies.json)
        echo "${proxy_group},${proxy_now}" >> /tmp/proxy-selected-tmp
      fi
    done
    [ -f /tmp/proxy-selected-tmp ] && mv /tmp/proxy-selected-tmp "${CLASH_PATH}/proxy-selected"
    rm /tmp/clash_proxies.json
  fi
}

load(){
  if [ ! -f "${CLASH_PATH}/proxy-selected" ]; then
    exit 0
  fi
  # waiting for clash to start up
  i=1
  while [ $i -lt 10 ]; do
    sleep 1
    test=$(curl -s -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT})
    [ -n "$test" ] && i=10
  done

  while read proxy_line; do
    group_name=$(echo "${proxy_line}" | awk -F ',' '{print $1}' | sed 's/ /%20/g')
    now_name=$(echo "${proxy_line}" | awk -F ',' '{print $2}')
    curl -sS -X PUT  \
          -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" \
          -H "Content-Type:application/json" \
          -d "{\"name\":\"${now_name}\"}" \
          "http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT}/proxies/${group_name}" >/dev/null
  done < "${CLASH_PATH}/proxy-selected"
}

case "$1" in

save)
        save
    ;;
load)
        load
    ;;
esac

exit 0