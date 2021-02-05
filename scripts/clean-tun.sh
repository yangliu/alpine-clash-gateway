#!/bin/ash

. /opt/acg/files/acg-cfg

ip route del default dev utun table "$IPROUTE2_TABLE_ID"
ip rule del fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID"

nft -f - << EOF
flush table clash
delete table clash
EOF

exit 0
