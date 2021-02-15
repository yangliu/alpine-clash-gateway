# Alpine Clash Gateway (ACG)

Quickly convert your Alpine Linux host/vm into a Clash-based gateway.

## Usage
1. Install Alpine Linux with `setup-alpine`.
2. Please configure your network during the installation. Static IP is recommended but not mandatory.
3. Run following command, and follow the instruction.
```
wget -O - https://cdn.jsdelivr.net/gh/yangliu/alpine-clash-gateway@0.1.3/scripts/install.sh | sh
```
or
```
wget -O - https://cdn.jsdelivr.net/gh/yangliu/alpine-clash-gateway@0.1.3/scripts/install.sh | sh -s /etc/acg
```

## Diskless Mode
Started from 0.1.2, ACG supports Alpine installation in Diskless Mode. Diskless Mode brings a lot of benefits including less-writings to the storage, easily survive from power loss, easy to backup settings, etc. This is especially useful when you plan to deploy your Clash gateway on an embeded device such as a Raspberry Pi (We actually tested ACG on a Raspberry Pi 4). To use Diskless Mode, please ensure

1. Install Alpine in __Diskless Mode__.
2. Choose __Diskless Mode__ during the installation of ACG.

However, Diskless mode also brings extra steps when you wanna persist settings (e.g., install and configure ACG). Please make sure to run _lbu ci_ to persist your changes. You can also do LBU Commit through the UI of ACG. ACG also provide an option to automatic LBU commit as ACG stops. This will allow ACG to run _lbu ci_ as ACG stop/restart, and during system shutdown/reboot. You can turn on this feature through ACG UI. However, we do not recommend to use this feature when your storage device is slow (e.g., an SD card), because it will significantly increase the time for ACG restart, system shutdown and reboot. It could also potentially commit some undesired changes that were made outside ACG.

## REST API
Started from 0.1.3, ACG supports a RESTful API to control ACG by http requests. It is useful to integrate ACG into other systems. 
For example, we can ask ACG to fetch new configuration and restart Clash as we write a new config.yaml and upload to the webserver.
To access the API, an HTTP request header should be added for authentication
```
SECRET: $CLASH_EXTERNAL_CONTROLLER_SECRET
```