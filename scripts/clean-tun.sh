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

ip route del default dev utun table "$IPROUTE2_TABLE_ID"
ip rule del fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID"

nft -f - << EOF
flush table ip clash
delete table ip clash
EOF

exit 0
