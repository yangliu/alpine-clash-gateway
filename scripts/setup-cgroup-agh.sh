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

if [ -z "${BYPASS_CGROUP_CLASSID_AGH}" ]; then
  echo "AdGuard Home is not installed or not properly configured."
  echo "Missing BYPASS_CGROUP_CLASSID_AGH"
  exit 0
fi

if [ -d "/sys/fs/cgroup/net_cls/bypass_proxy_agh" ];then
    exit 0
fi

if [ ! -d "/sys/fs/cgroup/net_cls" ];then
    mkdir -p /sys/fs/cgroup/net_cls
    
    mount -onet_cls -t cgroup net_cls /sys/fs/cgroup/net_cls
fi

mkdir -p /sys/fs/cgroup/net_cls/bypass_proxy_agh
echo "$BYPASS_CGROUP_CLASSID_AGH" > /sys/fs/cgroup/net_cls/bypass_proxy_agh/net_cls.classid
chmod 666 /sys/fs/cgroup/net_cls/bypass_proxy_agh/tasks
