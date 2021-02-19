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

is_agh_running() {
  rc-service -q adguardhome status
  return $?
}

get_current_ip() {
  ip=$(ifconfig | grep -A 1 "${CLASH_INTERFACE_NAME}" | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)
  echo "${ip}"
}


CLASH_CONFIG="${CLASH_PATH}/config.yaml"
if [ ! -f "${CLASH_CONFIG}" ]; then
  echo "Cannot find ${CLASH_CONFIG}."
  exit 1
fi

redir_port=$(yq r "${CLASH_CONFIG}" 'redir-port')
if [ ! -z $redir_port ]; then
    routing_mode="redir_tun"
else
    routing_mode="tun"
fi
[ -z "${ROUTING_MODE}" ] && ROUTING_MODE="auto"
case "${ROUTING_MODE}" in
    auto)
            :
        ;;
    redir_tun)
            routing_mode="redir_tun"
        ;;
    tun)
            routing_mode="tun"
        ;;
    *)
            :
        ;;
esac

if is_agh_running ; then
    agh_config="/opt/AdGuardHome/AdGuardHome.yaml"
    agh_dns_host=$(get_current_ip)
    agh_dns_port=$(yq r "${agh_config}" 'dns.port')
    if [ -z "${agh_dns_host}" ] || [ -z "${agh_dns_port}" ]; then
        :
    else
        FORWARD_DNS_REDIRECT="${agh_dns_host}:${agh_dns_port}"
    fi
fi

ip route replace default dev utun table "$IPROUTE2_TABLE_ID"

ip rule del fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID" > /dev/null 2> /dev/null
ip rule add fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID"

case "${routing_mode}" in
tun)
nft -f - << EOF
define LOCAL_SUBNET = {127.0.0.0/8, 224.0.0.0/4, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12}

table ip clash
flush table ip clash

table ip clash {
    chain local {
        type route hook output priority 0; policy accept;
        
        ip protocol != { tcp, udp } accept
        
        meta cgroup $BYPASS_CGROUP_CLASSID accept
        meta cgroup $BYPASS_CGROUP_CLASSID_AGH accept
        ip daddr \$LOCAL_SUBNET accept
        
        ct state new ct mark set $NETFILTER_MARK
        ct mark $NETFILTER_MARK mark set $NETFILTER_MARK
    }
    
    chain forward {
        type filter hook prerouting priority 0; policy accept;
        
        ip protocol != { tcp, udp } accept
    
        iif utun accept
        ip daddr \$LOCAL_SUBNET accept
        
        mark set $NETFILTER_MARK
    }
    
    chain local-dns-redirect {
        type nat hook output priority 0; policy accept;
        
        ip protocol != { tcp, udp } accept
        
        meta cgroup $BYPASS_CGROUP_CLASSID accept
        meta cgroup $BYPASS_CGROUP_CLASSID_AGH accept
        ip daddr 127.0.0.0/8 accept
        
        udp dport 53 dnat $FORWARD_DNS_REDIRECT
        tcp dport 53 dnat $FORWARD_DNS_REDIRECT
    }
    
    chain forward-dns-redirect {
        type nat hook prerouting priority 0; policy accept;
        
        ip protocol != { tcp, udp } accept
        
        udp dport 53 dnat $FORWARD_DNS_REDIRECT
        tcp dport 53 dnat $FORWARD_DNS_REDIRECT
    }
}
EOF
    ;;
redir_tun)
FORWARD_DNS_REDIRECT_HOST=$(echo "${FORWARD_DNS_REDIRECT}" | awk -F':' '{print $1}')
FORWARD_DNS_REDIRECT_PORT=$(echo "${FORWARD_DNS_REDIRECT}" | awk -F':' '{print $2}')

nft -f - << EOF
define LOCAL_SUBNET = {127.0.0.0/8, 224.0.0.0/4, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12}

table ip clash
flush table ip clash

table ip clash {
    chain route-output {
        type route hook output priority filter; policy accept;
        
        meta cgroup $BYPASS_CGROUP_CLASSID accept
        meta cgroup $BYPASS_CGROUP_CLASSID_AGH accept
        ip daddr \$LOCAL_SUBNET accept
        
        ip daddr . tcp dport {$FORWARD_DNS_REDIRECT_HOST . $FORWARD_DNS_REDIRECT_PORT} meta mark set $NETFILTER_MARK
        ip protocol != udp accept
        ct state new ct mark set $NETFILTER_MARK
        ct mark $NETFILTER_MARK meta mark set $NETFILTER_MARK
    }

    chain output {
        type nat hook output priority filter; policy accept;
        
        ip protocol != { tcp, udp } accept
        
        meta cgroup $BYPASS_CGROUP_CLASSID accept
        meta cgroup $BYPASS_CGROUP_CLASSID_AGH accept

        ip daddr 127.0.0.0/8 accept
        udp dport 53 dnat $FORWARD_DNS_REDIRECT
        tcp dport 53 dnat $FORWARD_DNS_REDIRECT

        ip daddr \$LOCAL_SUBNET accept
        ip protocol tcp redirect to :$redir_port
    }
    
    
    chain filter-prerouting {
        type filter hook prerouting priority filter; policy accept;
        
        iif utun accept
        ip daddr \$LOCAL_SUBNET accept
        
        ip daddr . tcp dport {$FORWARD_DNS_REDIRECT_HOST . $FORWARD_DNS_REDIRECT_PORT} meta mark set $NETFILTER_MARK
        ip protocol udp meta mark set $NETFILTER_MARK
    }

    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;

        ip protocol != { tcp, udp } accept
        udp dport 53 dnat $FORWARD_DNS_REDIRECT
        tcp dport 53 dnat $FORWARD_DNS_REDIRECT

        iif utun accept
        ip daddr \$LOCAL_SUBNET accept
        ip protocol tcp redirect to :$redir_port 
    }
    
}
EOF
    ;;
esac

sysctl -w net/ipv4/ip_forward=1
sysctl -w net.ipv4.conf.utun.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0

exit 0
