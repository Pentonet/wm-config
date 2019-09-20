#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd
#


#shellcheck disable=SC1090

# host_reboot
#
# performs a system reboot
function host_reboot
{
    local _MIN_TO_REBOOT

    _MIN_TO_REBOOT=${1:-"${WM_CFG_REBOOT_DELAY}"}

    web_notify "device rebooting in +${_MIN_TO_REBOOT}"
    ${WM_CFG_SUDO} shutdown --reboot "+${_MIN_TO_REBOOT}"
}


# host_upgrade
#
# Fetches updates from the package manager
function host_upgrade
{

    if [[ "${WM_HOST_UPGRADE_PACKAGES}" == "true" ]]
    then
        web_notify "upgrading host packages"
        ${WM_CFG_SUDO} apt-get update
        ${WM_CFG_SUDO} apt-get upgrade -y
        wm_config_set_entry "WM_HOST_UPGRADE_PACKAGES" "false"
    fi
}

## host_rm_win_linefeed
function host_rm_win_linefeed
{

    local _INPUT
    local _OUTPUT

    _INPUT=${1}
    _OUTPUT=${2}

    tr -d '\15\32' < "${_INPUT}" > "${_OUTPUT}"
}

# host_install_dependencies
#
# Sources dependencies from the ENTRYPOINT partition
function host_install_dependencies
{

    if [[ "${WM_HOST_INSTALL_DEPENDENCIES}" == "true" ]]
    then

        if [[ -f "${WM_CFG_SETTINGS_PATH}/host_dependencies.sh" ]]
        then
            web_notify "installing ${WM_CFG_SETTINGS_PATH}/host_dependencies.sh "

            ${WM_CFG_SUDO} cp --no-preserve=mode,ownership \
                "${WM_CFG_SETTINGS_PATH}/host_dependencies.sh" \
                "${WM_CFG_SESSION_STORAGE_PATH}/host_dependencies.tmp"

            host_rm_win_linefeed "${WM_CFG_SESSION_STORAGE_PATH}/host_dependencies.tmp" "${WM_CFG_INSTALL_PATH}/host_dependencies.sh"

            chmod +x "${WM_CFG_INSTALL_PATH}/host_dependencies.sh"
            ${WM_CFG_SUDO} "${WM_CFG_INSTALL_PATH}/host_dependencies.sh" || true
        fi

        if [[ -f "${WM_CFG_HOST_PATH}/host_dependencies.sh" ]]
        then
            web_notify "installing ${WM_CFG_HOST_PATH}/host_dependencies.sh"
            chmod +x "${WM_CFG_HOST_PATH}/host_dependencies.sh"
            ${WM_CFG_SUDO}  "${WM_CFG_HOST_PATH}/host_dependencies.sh"
        fi

        host_pip_install "${WM_CFG_SETTINGS_PATH}/requirements.txt"
        host_pip_install "${WM_CFG_HOST_PATH}/requirements.txt"

        export PATH=$PATH:/home/${USER}/.local/bin
        wm_config_set_entry "WM_HOST_INSTALL_DEPENDENCIES" "false"
        docker_add_user

        if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
        then
            host_reboot 0
            exit 0
        else
            echo "a reboot is mandatory for your user to gain acces to the docker engine"
            exit 0
        fi
    fi
}


# host_pip_install
#
# installs requirements for python using pip
function host_pip_install
{

    local _REQUIREMENTS

    _REQUIREMENTS=${1:-""}

    if [[ -f "${_REQUIREMENTS}" ]]
    then
        web_notify "installing ${_REQUIREMENTS}"

        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership \
            "${_REQUIREMENTS}" \
            "${WM_CFG_SESSION_STORAGE_PATH}/requirements.tmp"

        host_rm_win_linefeed "${WM_CFG_SESSION_STORAGE_PATH}/requirements.tmp" "${WM_CFG_INSTALL_PATH}/requirements.txt"

        pip3 install --user -r "${WM_CFG_INSTALL_PATH}/requirements.txt"
        echo "export PATH=$PATH:/home/${USER}/.local/bin" >> ~/.profile
    fi
}


# host_sync_clock
#
# forces a ntp sync by restarting the ntp service
function host_sync_clock
{
    web_notify "restarting systemd-timesyncd"
    ${WM_CFG_SUDO} systemctl status systemd-timesyncd >> "${WM_CFG_INSTALL_PATH}/.wirepas_session" || true
    ${WM_CFG_SUDO} systemctl restart systemd-timesyncd  || true
}


# host_systemd_management
#
# starts or stops the wirepas updater
function host_systemd_management
{
    web_notify "reloading systemd services"

    if [[ "${WM_SYSTEMD_UPDATER_DISABLE}" == "true" ]]
    then
        web_notify "disabling wirepas-updater"
        ${WM_CFG_SUDO} systemctl stop "${WM_SYSTEMD_UPDATER}" || true
        ${WM_CFG_SUDO} systemctl disable "${WM_SYSTEMD_UPDATER}" || true
        wm_config_set_entry "WM_SYSTEMD_UPDATER_DISABLE" "false"
        exit 0
    fi

    if [[ "${WM_SYSTEMD_UPDATER_ENABLE}" == "true" ]]
    then

        local _TARGET
        local _TARGET_TMP

        _TARGET="/etc/systemd/system/${WM_SYSTEMD_UPDATER}.service"
        _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/${WM_SYSTEMD_UPDATER}.service.tmp"

        wm_config_template_copy "${WM_SYSTEMD_UPDATER}" "${_TARGET_TMP}"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
        rm "${_TARGET_TMP}"

        ${WM_CFG_SUDO} systemctl daemon-reload
        ${WM_CFG_SUDO} systemctl enable "${WM_SYSTEMD_UPDATER}"

        wm_config_set_entry "WM_SYSTEMD_UPDATER_ENABLE"  "false"
        host_schedule_future 1
    fi
}

# host_blacklist_ipv6
#
# blacklists ipv6 module and reboot the host
function host_blacklist_ipv6
{
    local _TARGET
    local _TARGET_TMP

    _TARGET="/etc/sysctl.conf"
    _TARGET_TMP=${WM_CFG_SESSION_STORAGE_PATH}/ipv6.tmp

    if [[ "${WM_HOST_IPV6_DISABLE}" == "true" ]]
    then
        web_notify "blacklisting ipv6"

        ${WM_CFG_SUDO} cp "${_TARGET}" "${_TARGET_TMP}"
        ${WM_CFG_SUDO} chown "$(id -u):$(id -g)" "${_TARGET_TMP}"

        { \
            echo "net.ipv6.conf.all.disable_ipv6=1"; \
            echo "net.ipv6.conf.default.disable_ipv6=1"; \
            echo "net.ipv6.conf.lo.disable_ipv6=1";\
        } >> "${_TARGET_TMP}"

        ${WM_CFG_SUDO} cp "${_TARGET_TMP}" "${_TARGET}"
        ${WM_CFG_SUDO} chown root:root "${_TARGET}"

        wm_config_set_entry "WM_HOST_IPV6_DISABLE"  "false"

        host_reboot 0
        exit 0
    fi
}


# host_ssh_network_login
#
# sets the network logins for the main user
function host_ssh_network_login
{

    local _SERVICES
    local _SERVICE
    local _TARGET
    local _TARGET_TMP

    local _SERVICES=( "${WM_HOST_AVAHI_SERVICES}" )

    ${WM_CFG_SUDO} touch /boot/ssh

    for _SERVICE in "${_SERVICES[@]}"
    do
        web_notify "advertising avahi service: ${_SERVICE}"
        ${WM_CFG_SUDO} cp "${_SERVICE}" /etc/avahi/services/
    done

    ${WM_CFG_SUDO} systemctl restart avahi-daemon.service

    if [[ "${WM_HOST_SSH_ENABLE_NETWORK_LOGIN}" == "true" ]]
    then
        ${WM_CFG_SUDO} sed -i "s#PasswordAuthentication no#PasswordAuthentication yes#" /etc/ssh/sshd_config
    else
        _TARGET="/etc/ssh/sshd_config"
        _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/sshd_config.tmp"

        wm_config_template_copy sshd_config "${_TARGET_TMP}"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
        rm "${_TARGET_TMP}"

        ${WM_CFG_SUDO} sed -i "s#PasswordAuthentication yes#PasswordAuthentication no#" /etc/ssh/sshd_config
    fi

    ${WM_CFG_SUDO} systemctl restart ssh
}


# host_rpi_expand_filesystem
#
# expands the filesystem
function host_expand_filesystem
{
    if [[ "${WM_HOST_EXPAND_FILESYSTEM}" == "true" ]]
    then
        if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
        then
            web_notify "expanding filesystem"
            wm_config_set_entry "WM_HOST_EXPAND_FILESYSTEM"  "false"
            ${WM_CFG_SUDO} raspi-config --expand-rootfs
            web_notify "I am rebooting to expand the filesystem"
            host_reboot 0
            exit
        else
            echo "skipping file system increase"
        fi
    fi
}

# host_setup_hostname
#
# sets the system hostname
function host_setup_hostname
{
    local _HOSTNAME
    local _SET_HOSTNAME

    _HOSTNAME=$(hostname)

    if [[ ! -z "${WM_HOST_HOSTNAME}" && "${WM_HOST_HOSTNAME}" != "${_HOSTNAME}" ]]
    then
        ${WM_CFG_SUDO} hostnamectl set-hostname "${WM_HOST_HOSTNAME}"
        _SET_HOSTNAME=$(hostname)
        web_notify "changing hostname to: ${_SET_HOSTNAME}"
        ${WM_CFG_SUDO} sed -i "s/${_HOSTNAME}/${_SET_HOSTNAME}/g" /etc/hostname
        ${WM_CFG_SUDO} sed -i "s/${_HOSTNAME}/${_SET_HOSTNAME}/g" /etc/hosts
        wm_config_set_entry "WM_HOST_HOSTNAME" "${WM_HOST_HOSTNAME}"
        export WM_HOST_HOSTNAME="${_SET_HOSTNAME}"
        ${WM_CFG_SUDO} systemctl restart avahi-daemon
    else
        echo "keeping hostname ${_HOSTNAME}"
    fi
}

# host_setup_wifi
#
# Enables or disables the wifi interface
# An empty SSID or WM_WIFI_ENABLE to true will stop the wifi interface
function host_setup_wifi
{

    local _TEMPLATE

    if [[ "${WM_WIFI_ENABLE}" == "true" && ! -z "${WM_WIFI_AP_SSID}" ]]
    then
        _TEMPLATE=${WM_WIFI_TEMPLATE:-"wpa_supplicant"}

        web_notify "configuring WiFi client to: ${WM_WIFI_AP_SSID} / ${WM_WIFI_AP_PASSWORD}"

        wm_config_template_copy "${_TEMPLATE}" "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership  "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf" /etc/wpa_supplicant/wpa_supplicant.conf
        ${WM_CFG_SUDO} wpa_cli -i wlan0 reconfigure || true
        ifconfig wlan0 > "${WM_CFG_SESSION_STORAGE_PATH}/.wlan0.tmp" ||true

        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/.wlan0.tmp" "${WM_CFG_SESSION_STORAGE_PATH}/wlan0.log"
        ${WM_CFG_SUDO} rm "${WM_CFG_SESSION_STORAGE_PATH}/.wlan0.tmp"
        ${WM_CFG_SUDO} rm "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf"

    else
        web_notify "ensuring WiFi client is down"
        ${WM_CFG_SUDO} ifdown wlan0 || true
    fi

}

# host_setup_user
#
# evaluates the user passwords and public keys
function host_setup_user
{

    local _SETUP_USER_NAME
    local _SETUP_USER_PWD
    local _SETUP_USER_PPKI
    local _SSH_FOLDER

    _SETUP_USER_NAME=${1:-}
    _SETUP_USER_PWD=${2:-}
    _SETUP_USER_PPKI=${3:-}
    _SSH_FOLDER="/home/${_SETUP_USER_NAME}/.ssh/"

    if [[ ! -z "${_SETUP_USER_NAME}"  && ! -z "${_SETUP_USER_PWD}" ]]
    then
        web_notify "applying new password for ${_SETUP_USER_NAME}:${_SETUP_USER_PWD}"
        echo "${_SETUP_USER_NAME}:${_SETUP_USER_PWD}" | ${WM_CFG_SUDO} chpasswd
    fi

    if [[ ! -z "${_SETUP_USER_PPKI}" && ! -z "${_SETUP_USER_NAME}"  &&  ! -z "${_SETUP_USER_PWD}" ]]
    then
        if [[ ! -d "/home/${_SETUP_USER_NAME}/.ssh/" ]]
        then
            ${WM_CFG_SUDO} mkdir -p "${_SSH_FOLDER}"
        fi

        if [[ ! -f "/home/${_SETUP_USER_NAME}/.ssh/authorized_keys" ]]
        then
            ${WM_CFG_SUDO} touch "/home/${_SETUP_USER_NAME}/.ssh/authorized_keys"
        fi

        ${WM_CFG_SUDO} cp "/home/${_SETUP_USER_NAME}/.ssh/authorized_keys" "${WM_CFG_SESSION_STORAGE_PATH}/.authorized_keys.tmp"
        ${WM_CFG_SUDO} chown "${USER}:${USER}" "${WM_CFG_SESSION_STORAGE_PATH}/.authorized_keys.tmp"

        if grep -Fxq "${_SETUP_USER_PPKI}" "${WM_CFG_SESSION_STORAGE_PATH}/.authorized_keys.tmp"
        then
            web_notify "ssh key already authorized"
        else
            web_notify "adding authorized ssh key: ${_SETUP_USER_NAME}@${_SETUP_USER_PPKI}"
            echo "${_SETUP_USER_PPKI}" >> "${WM_CFG_SESSION_STORAGE_PATH}/.authorization.tmp"
            ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/.authorization.tmp" "/home/${_SETUP_USER_NAME}/.ssh/authorized_keys"
            ${WM_CFG_SUDO} rm "${WM_CFG_SESSION_STORAGE_PATH}/.authorization.tmp"
            ${WM_CFG_SUDO} rm "${WM_CFG_SESSION_STORAGE_PATH}/.authorized_keys.tmp"
        fi

        ${WM_CFG_SUDO} chown -R "${_SETUP_USER_NAME}:${_SETUP_USER_NAME}" "${_SSH_FOLDER}"
        ${WM_CFG_SUDO} systemctl restart ssh.service || true
    fi

}


# host_tty_pseudo_names
#
# sets custom tty names
function host_tty_pseudo_names
{

    local _TARGET
    local _TARGET_TMP

    if [[ ! -z "${WM_HOST_TTY_SYMLINK}" ]]
    then
        _TARGET="/etc/udev/rules.d/99-usb-serial.rules"
        _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/99-usb-serial.rules.tmp"

        web_notify "creating tty symlink => ${WM_HOST_TTY_SYMLINK}"
        wm_config_template_copy 99-usb-serial "${_TARGET_TMP}"

        if grep -Fxq "${WM_HOST_TTY_SYMLINK}" "${_TARGET_TMP}"
        then
            web_notify "symlink already present: ${WM_HOST_TTY_SYMLINK}"
        else
            ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
            wm_config_set_entry "WM_HOST_TTY_SYMLINK"
        fi
        rm "${_TARGET_TMP}"
    fi

}

# host_set_aws_credentials
#
# configures the host with aws credentials
function host_set_aws_credentials
{
    if [[ ! -z "${WM_AWS_ACCESS_KEY_ID}" && ! -z "${WM_AWS_SECRET_ACCESS_KEY}" ]]
    then
        web_notify "configuring aws client"
        mkdir -p "${HOME}/.aws"
        wm_config_template_copy "aws_credentials ${HOME}/.aws/credentials"
        wm_config_template_copy "aws_config ${HOME}/.aws/config"
    fi
}


# host_schedule_future
#
# Schedules the daemon to restart in the future
function host_schedule_future
{
    web_notify "scheduling job restart and exitting"
    ${WM_CFG_SUDO} systemctl daemon-reload
    ${WM_CFG_SUDO} systemctl restart "${WM_SYSTEMD_UPDATER}"
    exit 0
}


# host_set_keyboard_layout
#
# Defines the host keyboard model and options
function host_set_keyboard_layout
{
    if [[ "${WM_HOST_KEYBOARD_CONFIGURE}" == "true" ]]
    then
        web_notify "setting keyboard layout to model->${WM_HOST_KEYBOARD_XKBMODEL} layout->${WM_HOST_KEYBOARD_XKBLAYOUT}"

        wm_config_template_copy keyboard "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp"
        ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp" /etc/default/keyboard
        ${WM_CFG_SUDO} chown root:root /etc/default/keyboard
        rm "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp"

        ${WM_CFG_SUDO} udevadm trigger --subsystem-match=input --action=change

        wm_config_set_entry "WM_HOST_KEYBOARD_CONFIGURE"  "false"
    fi
}


# host_service_tunnel
#
# checks if a support key is present and establishes a tunnel to the target server
function host_service_tunnel
{

    local _TARGET_TEMPLATE

    _TARGET_TEMPLATE=${WM_PHONE_TEMPLATE:-"wirepas-phone"}

    if [[ -f "${WM_SUPPORT_HOST_KEY}" ]]
    then
        web_notify "starting phone support to ${WM_SUPPORT_HOST_USER}@${WM_SUPPORT_HOST_NAME}:${WM_SUPPORT_HOST_PORT} (key: ${WM_SUPPORT_HOST_KEY_PATH})"

        ${WM_CFG_SUDO} cp "${WM_SUPPORT_HOST_KEY}" "${WM_SUPPORT_HOST_KEY_PATH}"
        ${WM_CFG_SUDO} chmod 400 "${WM_SUPPORT_HOST_KEY_PATH}"
        ${WM_CFG_SUDO} chown "$(id -u):$(id -g)" "${WM_SUPPORT_HOST_KEY_PATH}"

        wm_config_template_copy "${_TARGET_TEMPLATE}" "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service" /etc/systemd/system/wirepas-phone.service
        rm "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service"

        ${WM_CFG_SUDO} systemctl daemon-reload
        ${WM_CFG_SUDO} systemctl start wirepas-phone.service
    else
        web_notify "ensuring tunnel is down"
        ${WM_CFG_SUDO} systemctl stop wirepas-phone.service || true
        ${WM_CFG_SUDO} rm -f /etc/systemd/system/wirepas-phone.service || true
    fi
}


# host_dbus_policies
# Copies and configures dbus for access by the sink service
function host_dbus_policies
{
    local _TARGET
    local _TARGET_TMP

    if [[ ! -f "/etc/dbus-1/system.d/${WM_GW_DBUS_CONF}" ]]
    then
        _TARGET="/etc/dbus-1/system.d/${WM_GW_DBUS_CONF}"
        _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/${WM_GW_DBUS_CONF}.tmp"

        wm_config_template_copy "${WM_GW_DBUS_CONF}" "${_TARGET_TMP}"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
        rm "${_TARGET_TMP}"

        if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
        then
            host_reboot 0
            exit 0
        else
            web_notify "added new dbus policy a reboot is advisable"
        fi
    fi
}


