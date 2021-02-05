# Alpine Clash Gateway (ACG)

Quickly convert your Alpine Linux host/vm into a Clash-based gateway.

## Usage
1. Install Alpine Linux with `setup-alpine` with traditional **Sys Disk Mode**. ACG may upgrade to support _Diskless Mode_ and _Data Disk Mode_ in future.
2. Please configure your network during the installation. Static IP is recommended but not mandatory.
3. Run following command
```
wget -O - https://cdn.jsdelivr.net/gh/yangliu/alpine-clash-gateway@main/scripts/install.sh | sh
```