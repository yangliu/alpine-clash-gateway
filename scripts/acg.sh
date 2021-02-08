#!/bin/sh

acg_path="/opt/acg"

# Load Configuration
if [ -f "${acg_path}/files/acg-cfg" ]; then
  . "${acg_path}/files/acg-cfg"
else
  if [ -f "${acg_path}/files/acg-cfg-sample" ]; then
    . "${acg_path}/files/acg-cfg-sample"
  else
    echo "The configuration file is missing. Please re-run the installation script."
    exit 1
  fi
fi
# Load Version
. "${acg_path}/files/version"


is_acg_running() {
  if [ -f /run/acg.pid ]; then
    return 0
  else
    return 1
  fi
}

do_update_clash_cfg() {
  ${acg_path}/scripts/update-clash.sh config
  es=$?
  if [ $es = 0 ]; then
    if (whiptail --title "ACG Updater" --yesno "Clash configuration has been updated successfully. Do you want to restart Clash?" 10 60) then
      rc-service acg restart
    else
      break
    fi
  else
    if [ $es = 2 ]; then
      whiptail --title "ACG Updater" --msgbox "Current Clash configuration is up to date." 10 60
    else
      whiptail --title "ACG Updater" --msgbox "Failed to update Clash configuration. Please check your settings." 10 60
    fi
  fi
}

do_update_clash_core() {
  ${acg_path}/scripts/update-clash.sh clash
  es=$?
  if [ $es = 0 ]; then
    if (whiptail --title "ACG Updater" --yesno "Clash core has been updated successfully. Do you want to restart Clash?" 10 60) then
      rc-service acg restart
    else
      break
    fi
  else
    if [ $es = 2 ]; then
      whiptail --title "ACG Updater" --msgbox "Clash core is up to date." 10 60
    else
      whiptail --title "ACG Updater" --msgbox "Failed to update Clash core. Please check your internet or upload the core manually." 10 60
    fi
  fi
}

do_update_clash_geoip() {
  ${acg_path}/scripts/update-clash.sh geoip
  es=$?
  if [ $es = 0 ]; then
    if (whiptail --title "ACG Updater" --yesno "GeoIP database has been updated successfully. Do you want to restart Clash?" 10 60) then
      rc-service acg restart
    else
      break
    fi
  else
    if [ $es = 2 ]; then
      whiptail --title "ACG Updater" --msgbox "GeoIP database is up to date." 10 60
    else
      whiptail --title "ACG Updater" --msgbox "Failed to update GeoIP database. Please check your internet or upload Country.mmdb manually." 10 60
    fi
  fi
}

do_update_yacd() {
  ${acg_path}/scripts/update-clash.sh yacd
  es=$?
  if [ $es = 0 ]; then
      whiptail --title "ACG Updater" --msgbox "YACD has been updated successfully." 10 60
  else
    if [ $es = 2 ]; then
      whiptail --title "ACG Updater" --msgbox "YACD is up to date." 10 60
    else
      whiptail --title "ACG Updater" --msgbox "Failed to update YACD. Please check your internet or update it manually." 10 60
    fi
  fi
}

do_1_key_update() {
  updated_cfg=0
  updated_clash=0
  updated_geoip=0
  ${acg_path}/scripts/update-clash.sh config
  es=$?
  if [ $es -eq 0 ]; then
    updated_cfg=1
  fi
  ${acg_path}/scripts/update-clash.sh clash
  es=$?
  if [ $es -eq 0 ]; then
    updated_clash=1
  fi
  ${acg_path}/scripts/update-clash.sh geoip
  es=$?
  if [ $es -eq 0 ]; then
    updated_geoip=1
  fi
  ${acg_path}/scripts/update-clash.sh yacd

  need_restart_clash=0
  updated_str=""
  for id in "cfg" "clash" "geoip" ; do
    eval assign="\$updated_$id"
    if [ $assign -eq 1 ]; then
      need_restart_clash=1
      updated_str="${updated_str} ${id}"
    fi
  done


  if [ ${need_restart_clash} -eq 1 ]; then
    updated_str=$(echo "${updated_str}" | xargs)
    if (whiptail --title "ACG Updater" --yesno "Found changes in ${updated_str}. Do you want to restart Clash?" 10 60) then
      rc-service acg restart
    else
      break
    fi
  else
    whiptail --title "ACG Updater" --msgbox "Clash core, GeoIP DB, and config.yaml are all up to date." 10 60
  fi
}

do_start_stop_clash() {
  if is_acg_running ; then
    rc-service acg stop
  else
    rc-service acg start
  fi
}

do_restart_clash() {
  if is_acg_running ; then
    rc-service acg restart
  else
    rc-service acg start
  fi
}

set_acg_cfg(){
  acg_cfg_file="${acg_path}/files/acg-cfg"
  grep "${1}=" $acg_cfg_file >/dev/null
  if [ $? -eq 0 ]; then
    ESCAPED_KEYWORD=$(printf '%s\n' "${2}" | sed -e 's/[]\/$*.^[]/\\&/g');
    sed -i "s/${1}=.*$/${1}=${ESCAPED_KEYWORD}/g" $acg_cfg_file
  else
    echo "Cannot find '${1}' in ${acg_cfg_file}."
    return 1
  fi
}

do_set_acg_cfg() {
  acg_cfg_file="${acg_path}/files/acg-cfg"
  old_value=$(eval echo \${$3})
  u_value=$(whiptail --title "$1" --inputbox "$2" 10 60 "${old_value}" 3>&1 1>&2 2>&3)
  es=$?
  if [ $es = 0 ] && [[ "${u_value}" != "${old_value}" ]]; then
    set_acg_cfg "$3" "${u_value}"
    if [ $? -eq 0 ]; then
      whiptail --title "$1" --msgbox "${3} has been updated." 10 60
      . ${acg_cfg_file}
    else
      whiptail --title "$1" --msgbox "Failed to update ${3}." 10 60
    fi
  fi
}
do_set_interface_name() {
  do_set_acg_cfg "Set Interface Name" "Please specify the outbound interface (eg. eth0, ens1, wlan0)." "CLASH_INTERFACE_NAME"
}
do_set_arch() {
  do_set_acg_cfg "Set architecture" "Please provide your architecture (amd64, armv6 ...)." "CLASH_BIN_ARCH"
}

do_set_clash_cfg_url() {
  do_set_acg_cfg "Set Clash Config URL" "Please enter the url of Clash config (config.yaml)." "CLASH_CONFIG_URL"
}

do_set_clash_ec() {
  do_set_acg_cfg "Clash External Controller" "Please enter the port of Clash external-controller." "CLASH_EXTERNAL_CONTROLLER_PORT"
  do_set_acg_cfg "Clash External Controller" "Please enter the secret of Clash external-controller." "CLASH_EXTERNAL_CONTROLLER_SECRET"
  do_set_acg_cfg "Clash External Controller" "Please enter the relative path of Clash external-controller-ui." "CLASH_EXTERNAL_CONTROLLER_UI"
}

do_set_auto_lbu_ci() {
    if (whiptail --title "Auto LBU Commit" --yesno "Do you wish to do lbu commit as ACG stops?" 10 60 3>&1 1>&2 2>&3) then
      set_acg_cfg "AUTO_LBU_CI" "1"
    else
      set_acg_cfg "AUTO_LBU_CI" "0"
    fi
    . "${acg_path}/files/acg-cfg"
}

do_lbu_ci() {
  if [[ "${ALPINE_INSTALLATION_MODE}" == "diskless" ]]; then
    lbu ci
    if [ $? -eq 0 ]; then
      whiptail --title "LBU Commit" --msgbox "LBU Commit successfully." 10 60
    else
      whiptail --title "LBU Commit" --msgbox "Failed to do LBU Commit." 10 60
    fi
  else
    whiptail --title "LBU Commit" --msgbox "This is only useful under Diskless mode." 10 60
  fi
}

do_install_acg() {
  escaped_acg_path=$(printf '%s\n' "${acg_path}" | sed -e 's/[]\/$*.^[]/\\&/g');
  # check newt
  if [ ! -f /usr/bin/whiptail ]; then
    echo "Install newt"
    apk add --quiet --update newt
    if [ $? != 0 ]; then
      echo "Cannot satisfy the requirements. Please check your internet and your apk repositories. Make sure to enable the community repo."
    fi
  fi
  # check configure file
  if [ -f "${acg_path}/files/acg-cfg" ]; then
    if (whiptail --title "Alpine Clash Gateway" --yesno "You already have an ACG configuration file in your system. Continue installation may loss all your original settings. Do you want to continue?" 10 60) then
      :
    else
      exit 1
    fi
  fi

  cp "${acg_path}/files/acg-cfg-sample" "${acg_path}/files/acg-cfg"
  set_acg_cfg "CLASH_PATH" "${acg_path}/clash"
  . "${acg_path}/files/acg-cfg"

  if (whiptail --title "Alpine Clash Gateway" --yesno "This script will install Alpine Clash Gateway (ACG). It will turn your Alpine Linux host into a Clash gateway. Do you want to continue?" 10 60) then
    echo "Install all dependent packages"
    apk add --update nftables iproute2 udev curl jq
    if [ $? != 0 ]; then
      echo "Cannot satisfy the requirements. Please check your internet and your apk repositories. Make sure to enable the community repo."
    fi
    
    echo "Enable tun"
    lsmod | grep tun > /dev/null
    if [ $? != 0 ]; then
      echo "tun" > /etc/modules-load.d/tun.conf
      modprobe tun
    fi
    
    echo "Enable cgroups"
    rc-update --quiet add cgroups
    rc-service cgroups start

    echo "Enable udev"
    rc-update --quiet add udev
    rc-update --quiet add udev-trigger
    rc-update --quiet add udev-settle
    rc-service udev start
    rc-service udev-trigger start
    rc-service udev-settle start

    echo "Install Alpine Clash Gateway to ${acg_path}"
    mkdir -p "${acg_path}"
    chmod -R +x "${acg_path}/files/acg" "${acg_path}/scripts"

    cp "${acg_path}/files/99-clash.rules.orig" "/etc/udev/rules.d/99-clash.rules"
    sed -i "s/|ACG_PATH|/${escaped_acg_path}/g" /etc/udev/rules.d/99-clash.rules
    
    ln -s "${acg_path}/files/acg" /etc/init.d/

    echo "Now we need to configure ACG."

    # diskless mode
    "${acg_path}/files/acg-cfg"
    
    if (whiptail --title "Diskless Mode" --yes-button "Diskless Mode" --no-button "Sys Mode" --yesno "Is your Alpine installation in Diskless Mode?" 10 60 3>&1 1>&2 2>&3) then
      set_acg_cfg "ALPINE_INSTALLATION_MODE" "diskless"
      if ! case ${acg_path} in /etc*) ;; esac; then
        lbu add "${acg_path}"
      fi
      do_set_auto_lbu_ci
    else
      set_acg_cfg "ALPINE_INSTALLATION_MODE" "sys"
      . "${acg_path}/files/acg-cfg"
    fi
    
    do_set_clash_cfg_url
    do_set_interface_name
    do_set_arch
    do_set_clash_ec
    do_1_key_update

    rc-update --quiet add acg

    if [[ "${ALPINE_INSTALLATION_MODE}" == "diskless" ]]; then
      if [ "${AUTO_LBU_CI}" -eq 1 ]; then
        lbu ci
      else
        if (whiptail --title "ACG Installation" --yesno "ACG has been installed and running. Do you wish to do lbu commit to save the changes to your system?" 10 60 3>&1 1>&2 2>&3) then
          lbu ci
        fi
      fi
    fi

    echo "ACG has been installed."
    echo "Please set the client Gateway and DNS to the ip address of this host."
    echo "You can configure ACG with the following command"
    echo "${acg_path}/scripts/acg.sh"
    show_main
  else
    break
  fi

}

do_uninstall_acg() {
  if (whiptail --title "Alpine Clash Gateway" --yesno "This script will remove Alpine Clash Gateway (ACG) from your system. Do you want to continue?" 10 60) then
    do_start_stop_clash
    rc-update --quiet del acg
    rm /etc/init.d/acg
    rm /etc/udev/rules.d/99-clash.rules
    rm -rf "${acg_path}"
    echo "ACG has been removed from your system. However, the dependences are left in your system."
    echo "You can further remove all the dependences with the following commands"
    echo "rm /etc/modules-load.d/tun.conf"
    echo "rc-service cgroups stop"
    echo "rc-update del cgroups"
    echo "rc-service udev-settle stop"
    echo "rc-update del udev-settle"
    echo "rc-service udev-trigger stop"
    echo "rc-update del udev-trigger"
    echo "rc-service udev stop"
    echo "rc-update del udev"
    echo "apk del newt nftables iproute2 udev curl jq"
    exit 0
  fi
}


show_about() {
  whiptail --title "Alpine Clash Gateway" --msgbox "\
Alpine Clash Gateway (acg) is a bunch of shell scripts \
that conveniently converts an Alpine Linux host into a \
Clash gateway. It also make setup and configure Clash \
much easier.
" 10 60
}

show_main() {
  if is_acg_running ; then
    opt_4_text="Stop Clash"
  else
    opt_4_text="Start Clash"
  fi

  the_opt=$(whiptail --title "Alpine Clash Gateway (ACG)" \
  --cancel-button "Exit" \
  --notags \
  --menu "" 18 60 11 \
  "1" "Update Clash configuration" \
  "A" "One-key Update (config.yaml, clash, & geoip)" \
  "2" "Update Clash core" \
  "3" "Update GeoIP database" \
  "Y" "Update YACD" \
  "4" "${opt_4_text}" \
  "5" "Restart Clash" \
  "C" "LBU Commit" \
  "7" "Set the URL of Clash configuration" \
  "I" "Set Clash Outbound Interface" \
  "8" "Set Clash External Controller" \
  "L" "Set Auto LBU Commit" \
  "6" "Set Architecture" \
  "9" "Uninstall ACG" \
  "10" "About ACG" \
  3>&1 1>&2 2>&3)
  es=$?
  if [ $es = 0 ]; then
    case $the_opt in 

    1)
          do_update_clash_cfg
      ;;
    A)
          do_1_key_update
      ;;
    2)
          do_update_clash_core
      ;;
    3)
          do_update_clash_geoip
      ;;
    Y)
          do_update_yacd
      ;;
    4)
          do_start_stop_clash
      ;;
    5)
          do_restart_clash
      ;;
    6)
          do_set_arch
      ;;
    7)
          do_set_clash_cfg_url
      ;;
    I)
          do_set_interface_name
      ;;
    8)
          do_set_clash_ec
      ;;
    L)
          do_set_auto_lbu_ci
      ;;
    C)
          do_lbu_ci
      ;;
    9)
          do_uninstall_acg
      ;;

    10)
          show_about
      ;;

    esac
    show_main
  fi
  exit 0
}

if [ -z "$1" ]; then
  show_main
else
  case "$1" in
  install)
              do_install_acg
            ;;

  *)
              echo "Unknown command."
              exit 1
            ;;
  esac
fi
