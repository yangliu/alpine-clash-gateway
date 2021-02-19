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

CLASH_CONFIG="${CLASH_PATH}/config.yaml"
if [ ! -f "${CLASH_CONFIG}" ]; then
  echo "Cannot find ${CLASH_CONFIG}."
  exit 1
fi

yq w -i "${CLASH_CONFIG}" 'external-controller' ":${CLASH_EXTERNAL_CONTROLLER_PORT}"
yq w -i "${CLASH_CONFIG}" 'secret' "${CLASH_EXTERNAL_CONTROLLER_SECRET}"
yq w -i "${CLASH_CONFIG}" 'external-ui' "${CLASH_EXTERNAL_CONTROLLER_UI}"
yq w -i "${CLASH_CONFIG}" 'interface-name' "${CLASH_INTERFACE_NAME}"
yq w -i "${CLASH_CONFIG}" 'dns.listen' ":${CLASH_DNS_PORT}"
