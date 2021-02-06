#!/bin/ash

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

CLASH_CONFIG="${CLASH_PATH}/config.yaml"
if [ ! -f "${CLASH_CONFIG}" ]; then
  echo "Cannot find ${CLASH_CONFIG}."
  exit 1
fi

set_cfg_value(){
  grep "${1}:" $CLASH_CONFIG >/dev/null
  if [ $? -eq 0 ]; then
    sed -i "s/${1}:.*$/${1}: ${2}/g" $CLASH_CONFIG
  else
    echo "Cannot find '${1}' in ${CLASH_CONFIG}."
    exit 1
  fi
}

set_cfg_value "external-controller" ":${CLASH_EXTERNAL_CONTROLLER_PORT}"
set_cfg_value "secret" "${CLASH_EXTERNAL_CONTROLLER_SECRET}"
