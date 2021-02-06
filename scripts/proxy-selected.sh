#!/bin/ash

. /opt/acg/files/acg-cfg

save(){
  curl -s -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" \
    -H "Content-Type:application/json" \
    "http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT}/proxies" \
    | awk -F "{" '{for(i=1;i<=NF;i++) print $i}' \
    | grep -E '^"all".*"Selector"' > /tmp/acg-proxy-selected-save
  while read line ; do
    def=$(echo $line | awk -F "[\[,]" '{print $2}')
    now=$(echo $line | grep -oE '"now".*",' | sed 's/"now"://g'| sed 's/,//g')
    [ "$def" != "$now" ] && echo $line | grep -oE '"name".*"now".*",' | sed 's/"name"://g' | sed 's/"now"://g'| sed 's/"//g' >> /tmp/acg-proxy-selected-save2
  done < /tmp/acg-proxy-selected-save
  rm -rf /tmp/acg-proxy-selected-save

  if [ -s /tmp/acg-proxy-selected-save2 ]; then
    mv /tmp/acg-proxy-selected-save2 "${CLASH_PATH}/proxy-selected"
  fi
}

load(){
  if [ ! -f "${CLASH_PATH}/proxy-selected" ]; then
    exit 0
  fi
  # waiting for clash to start up
  i=1
  while [ $i < 10 ]; do
    sleep 1
    test=$(curl -s -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT})
    [ -n "$test" ] && i=10
  done

  num=$(cat ${CLASH_PATH}/proxy-selected | wc -l)
  for i in `seq $num`;
  do
    group_name=$(awk -F ',' 'NR=="'${i}'" {print $1}' ${CLASH_PATH}/proxy-selected | sed 's/ /%20/g')
    now_name=$(awk -F ',' 'NR=="'${i}'" {print $2}' ${CLASH_PATH}/proxy-selected)
    curl -sS -X PUT  \
          -H "Authorization: Bearer ${CLASH_EXTERNAL_CONTROLLER_SECRET}" \
          -H "Content-Type:application/json" \
          -d "{\"name\":\"${now_name}\"}" \
          "http://localhost:${CLASH_EXTERNAL_CONTROLLER_PORT}/proxies/${group_name}" >/dev/null
  done
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