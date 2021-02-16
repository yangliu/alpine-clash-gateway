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

if [ -d "/sys/fs/cgroup/net_cls/bypass_proxy" ];then
    exit 0
fi

if [ ! -d "/sys/fs/cgroup/net_cls" ];then
    mkdir -p /sys/fs/cgroup/net_cls
    
    mount -onet_cls -t cgroup net_cls /sys/fs/cgroup/net_cls
fi

mkdir -p /sys/fs/cgroup/net_cls/bypass_proxy
echo "$BYPASS_CGROUP_CLASSID" > /sys/fs/cgroup/net_cls/bypass_proxy/net_cls.classid
chmod 666 /sys/fs/cgroup/net_cls/bypass_proxy/tasks
