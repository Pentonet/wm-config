#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd
#

#shellcheck disable=SC1090


# host_reboot
#
# performs a system reboot
function host_reboot
{

    if [[ "${WM_HOST_REBOOT}" == "true" ]]
    then
        local _MIN_TO_REBOOT

        _MIN_TO_REBOOT=${1:-"${WM_CFG_REBOOT_DELAY}"}

        web_notify "device rebooting in +${_MIN_TO_REBOOT}"
        sudo shutdown --reboot "+${_MIN_TO_REBOOT}"
    fi
}


# host_docker_daemon_management management
#
# cleans up dangling images
function host_docker_daemon_management
{
    if [[ "${WM_HOST_DOCKER_PRUNE_ALL}" == "true" ]]
    then

        local _WIPE_ALL

        _WIPE_ALL=${1:-"${WM_DOCKER_CLEANUP}"}

        if [[ "${_WIPE_ALL}" == "true" ]]
        then
            #Necessary to allow successful completion on Raspbian buster see #25
            web_notify "removing all containers"
            #shellcheck disable=SC2046
            docker rm -f $( docker ps -aq) || true
            wm_config_set_entry "WM_DOCKER_CLEANUP" "false"
        fi

        # Necessary to allow successful completion on Raspbian buster see #25
        web_notify "pruning all _unused_ docker elements"
        docker system prune --all --force || true
    fi

    if [[ ! -z "${WM_DOCKER_USERNAME}" && ! -z "${WM_DOCKER_PASSWORD}" ]]
    then
        web_notify "Setting docker credentials for ${WM_DOCKER_USERNAME}"
        docker login --username "${WM_DOCKER_USERNAME}" --password "${WM_DOCKER_PASSWORD}"
    fi
}


## host_ensure_linux_lf
##
## Ensures a file does not contain linux line endings
function host_ensure_linux_lf
{

    local _INPUT
    local _TARGET_TMP
    _INPUT="${1:?}"
    _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/{1}.tmp"

    tr -d '\15\32' < "${_INPUT}" > "${_TARGET_TMP}"
    cp "${_TARGET_TMP}" "${_INPUT}"
}

# host_dependency_management
#
# Sources dependencies from the ENTRYPOINT partition
function host_dependency_management
{

    if [[ "${WM_HOST_UPGRADE_PACKAGES}" == "true" ]]
    then
        web_notify "upgrading host packages"
        sudo apt-get update
        sudo apt-get upgrade -y
        wm_config_set_entry "WM_HOST_UPGRADE_PACKAGES" "false"
    fi

    if [[ "${WM_HOST_INSTALL_DEPENDENCIES}" == "true" ]]
    then

        if [[ ! -d "/home/${USER}/.local/bin" ]]
        then
            mkdir -p "/home/${USER}/.local/bin"
        fi

        export PATH=$PATH:/home/${USER}/.local/bin

        if ! grep -Fxq "/home/${USER}/.local/bin" ~/.profile
        then
            echo "export PATH=$PATH:/home/${USER}/.local/bin" >> ~/.profile
        fi

        if [[ -f "${WM_CFG_HOST_DEPENDENCIES_PATH}/host_dependencies.sh" ]]
        then
            web_notify "installing ${WM_CFG_HOST_DEPENDENCIES_PATH}/host_dependencies.sh "
            chmod +x "${WM_CFG_HOST_DEPENDENCIES_PATH}/host_dependencies.sh"
            . "${WM_CFG_HOST_DEPENDENCIES_PATH}/host_dependencies.sh"
        fi

        host_pip_install "${WM_CFG_HOST_DEPENDENCIES_PATH}/requirements.txt"
        wm_config_set_entry "WM_HOST_INSTALL_DEPENDENCIES" "false"
        docker_add_user

        echo "A reboot is mandatory for your user to gain access to the docker engine!!"
        host_reboot 1
        exit 0
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
        source "${WM_CFG_PYTHON_VIRTUAL_ENV}/bin/activate"
        web_notify "installing python requirements ${_REQUIREMENTS} (under ${WM_CFG_PYTHON_VIRTUAL_ENV})"
        pip install -r "${_REQUIREMENTS}"
    fi
}


# host_clock_management
#
# forces a ntp sync by restarting the ntp service
function host_clock_management
{

    if [[ "${WM_HOST_CLOCK_MANAGEMENT}" == "true" ]]
    then
        web_notify "restarting systemd-timesyncd"
        sudo systemctl daemon-reload
        systemctl status systemd-timesyncd >> "${WM_CFG_INSTALL_PATH}/session.log" || true
        sudo systemctl restart systemd-timesyncd  || true
    fi
}


# host_systemd_management
#
# starts or stops the wirepas updater
function host_systemd_management
{

    if [[ "${WM_HOST_SYSTEMD_MANAGEMENT}" == "true" ]]
    then

        web_notify "reloading systemd services"
        if [[ "${WM_SYSTEMD_UPDATER_DISABLE}" == "true" ]]
        then
            web_notify "disabling wirepas-updater"
            sudo systemctl stop "${WM_SYSTEMD_UPDATER}" || true
            sudo systemctl disable "${WM_SYSTEMD_UPDATER}" || true
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
            sudo cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
            rm "${_TARGET_TMP}"

            sudo systemctl daemon-reload
            sudo systemctl enable "${WM_SYSTEMD_UPDATER}"

            wm_config_set_entry "WM_SYSTEMD_UPDATER_ENABLE"  "false"
            host_schedule_future 1
        fi
    fi
}

# host_ip_management
#
# blacklists ipv6 module and reboot the host
function host_ip_management
{

    if [[ "${WM_HOST_BLACKLIST_IPV6}" == "true" ]]
    then

        local _TARGET
        local _TARGET_TMP

        _TARGET="/etc/sysctl.conf"
        _TARGET_TMP=${WM_CFG_SESSION_STORAGE_PATH}/ipv6.tmp

        web_notify "blacklisting ipv6"

        sudo cp "${_TARGET}" "${_TARGET_TMP}"
        sudo chown "$(id -u):$(id -g)" "${_TARGET_TMP}"

        { \
            echo "net.ipv6.conf.all.disable_ipv6=1"; \
            echo "net.ipv6.conf.default.disable_ipv6=1"; \
            echo "net.ipv6.conf.lo.disable_ipv6=1";\
        } >> "${_TARGET_TMP}"

        sudo cp "${_TARGET_TMP}" "${_TARGET}"
        sudo chown root:root "${_TARGET}"

        wm_config_set_entry "WM_HOST_BLACKLIST_IPV6"  "false"

        host_reboot 0
        exit 0
    fi
}

# host_avahi_daemon_management
#
# configures the avahi daemon
function host_avahi_daemon_management
{
    if [[ "${WM_HOST_AVAHI_DAEMON_MANAGEMENT}" == "true" && ! -f /etc/avahi/services/ssh.service ]]
    then
        web_notify "advertising avahi service: ${WM_CFG_HOST_DEPENDENCIES_PATH}/ssh.service"
        sudo cp "${WM_CFG_HOST_DEPENDENCIES_PATH}/ssh.service" /etc/avahi/services/
        sudo systemctl restart avahi-daemon.service
    fi
}


# host_ssh_daemon_management
#
# sets the network logins for the main user
function host_ssh_daemon_management
{
    if [[ "${WM_HOST_SSH_DAEMON_MANAGEMENT}" == "true" ]]
    then
        local _TARGET
        local _TARGET_TMP

        host_avahi_daemon_management

        if [[ "${WM_HOST_SSH_ENABLE_PASSWORD_LOGIN}" == "true" ]]
        then
            sudo sed -i "s#PasswordAuthentication no#PasswordAuthentication yes#" /etc/ssh/sshd_config
        else
            _TARGET="/etc/ssh/sshd_config"
            _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/sshd_config.tmp"

            wm_config_template_copy sshd_config "${_TARGET_TMP}"
            sudo cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
            rm "${_TARGET_TMP}"

            sudo sed -i "s#PasswordAuthentication yes#PasswordAuthentication no#" /etc/ssh/sshd_config
        fi

        sudo systemctl restart ssh
    fi
}


# host_rpi_expand_filesystem
#
# expands the filesystem
function host_filesystem_management
{
    if [[ "${WM_HOST_FILESYSTEM_MANAGEMENT}" == "true" ]]
    then
        if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
        then
            web_notify "expanding filesystem"
            wm_config_set_entry "WM_HOST_FILESYSTEM_MANAGEMENT"  "false"
            sudo raspi-config --expand-rootfs
            web_notify "I am rebooting to expand the filesystem"
            host_reboot 0
            exit
        else
            echo "skipping file system increase"
        fi
    fi
}

# host_hostname_management
#
# sets the system hostname
function host_hostname_management
{
    if [[ "${WM_HOST_HOSTNAME_MANAGEMENT}" == "true" ]]
    then
        local _HOSTNAME
        local _SET_HOSTNAME

        _HOSTNAME=$(hostname)

        if [[ ! -z "${WM_HOST_HOSTNAME}" && "${WM_HOST_HOSTNAME}" != "${_HOSTNAME}" ]]
        then
            sudo hostnamectl set-hostname "${WM_HOST_HOSTNAME}"
            _SET_HOSTNAME=$(hostname)
            web_notify "changing hostname to: ${_SET_HOSTNAME}"
            sudo sed -i "s/${_HOSTNAME}/${_SET_HOSTNAME}/g" /etc/hostname
            sudo sed -i "s/${_HOSTNAME}/${_SET_HOSTNAME}/g" /etc/hosts
            wm_config_set_entry "WM_HOST_HOSTNAME" "${WM_HOST_HOSTNAME}"
            export WM_HOST_HOSTNAME="${_SET_HOSTNAME}"
            sudo systemctl restart avahi-daemon
        else
            echo "keeping hostname ${_HOSTNAME}"
        fi
    fi
}

# host_wifi_management
#
# Enables or disables the wifi interface
# An empty SSID or WM_WIFI_ENABLE to true will stop the wifi interface
function host_wifi_management
{
    if [[ "${WM_HOST_WIFI_MANAGEMENT}" == "true" ]]
    then

        local _TEMPLATE

        if [[ "${WM_WIFI_ENABLE}" == "true" && ! -z "${WM_WIFI_AP_SSID}" ]]
        then
            _TEMPLATE=${WM_WIFI_TEMPLATE:-"wpa_supplicant"}

            web_notify "configuring WiFi client to: ${WM_WIFI_AP_SSID} / ${WM_WIFI_AP_PASSWORD}"
            wm_config_template_copy "${_TEMPLATE}" "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf"
            sudo cp --no-preserve=mode,ownership  "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf" /etc/wpa_supplicant/wpa_supplicant.conf
            sudo ifconfig "${WM_WIFI_INTERFACE}" up || true
            sudo wpa_cli -i "${WM_WIFI_INTERFACE}" reconfigure || true
            ifconfig "${WM_WIFI_INTERFACE}" > "${WM_CFG_SESSION_STORAGE_PATH}/.${WM_WIFI_INTERFACE}.log" || true
            sudo rm "${WM_CFG_SESSION_STORAGE_PATH}/wpa_supplicant.conf"
        else
            web_notify "ensuring WiFi client is down"
            sudo ifdown "${WM_WIFI_INTERFACE}" || true
        fi
    fi

}

# host_schedule_future
#
# Schedules the daemon to restart in the future
function host_schedule_future
{
    if [[ "${WM_HOST_SYSTEMD_MANAGEMENT}" == "true" ]]
    then
        web_notify "scheduling job restart and exiting"
        sudo systemctl daemon-reload
        sudo systemctl restart "${WM_SYSTEMD_UPDATER}"
        exit 0
    fi
}


# host_user_management
#
# evaluates the user passwords and public keys
function host_user_management
{
    if [[ "${WM_HOST_USER_MANAGEMENT}" == "true" ]]
    then

        local _SSH_FOLDER
        _SSH_FOLDER="/home/${WM_HOST_USER_NAME}/.ssh/"

        if [[ ! -z "${WM_HOST_USER_NAME}"  && ! -z "${WM_HOST_USER_PASSWORD}" ]]
        then
            web_notify "applying new password for ${WM_HOST_USER_NAME}:${WM_HOST_USER_PASSWORD}"
            echo "${WM_HOST_USER_NAME}:${WM_HOST_USER_PASSWORD}" | sudo chpasswd
        fi

        if [[ ! -z "${WM_HOST_USER_PPKI}" && ! -z "${WM_HOST_USER_NAME}" ]]
        then
            if [[ ! -d "${_SSH_FOLDER}" ]]
            then
                mkdir -p "${_SSH_FOLDER}"
            fi

            if [[ ! -f "${_SSH_FOLDER}/authorized_keys" ]]
            then
                touch "${_SSH_FOLDER}/authorized_keys"
            fi

            if grep -Fxq "${WM_HOST_USER_PPKI}" "${_SSH_FOLDER}/authorized_keys"
            then
                web_notify "ssh key already authorized"
            else
                web_notify "adding authorized ssh key: ${WM_HOST_USER_NAME}@${WM_HOST_USER_PPKI}"
                echo "${WM_HOST_USER_PPKI}" >> "${_SSH_FOLDER}/authorized_keys"
            fi
        fi
    fi
}


# host_tty_management
#
# sets custom tty names
function host_tty_management
{
    if [[ "${WM_HOST_TTY_MANAGEMENT}" == "true" ]]
    then

        local _TARGET
        local _TARGET_TMP

        if [[ "${WM_HOST_TTY_SYMLINK}" != "none" ]]
        then
            _TARGET="/etc/udev/rules.d/${WM_HOST_TTY_SIMLINK_FILENAME}"
            _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/${WM_HOST_TTY_SIMLINK_FILENAME}.tmp"

            web_notify "creating tty symlink => ${WM_HOST_TTY_SYMLINK}"
            wm_config_template_copy "${WM_HOST_TTY_SIMLINK_FILENAME}" "${_TARGET_TMP}"

            if grep -Fxq "${WM_HOST_TTY_SYMLINK}" "${_TARGET_TMP}"
            then
                web_notify "symlink already present: ${WM_HOST_TTY_SYMLINK}"
            else
                sudo cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
                wm_config_set_entry "WM_HOST_TTY_SYMLINK" "none"

                # forces an update of the symlinks
                sudo udevadm trigger || true
            fi
            rm "${_TARGET_TMP}"
        fi
    fi
}



# host_keyboard_management
#
# Defines the host keyboard model and options
function host_keyboard_management
{
    if [[ "${WM_HOST_KEYBOARD_MANAGEMENT}" == "true" ]]
    then
        web_notify "setting keyboard layout to model->${WM_HOST_KEYBOARD_XKBMODEL} layout->${WM_HOST_KEYBOARD_XKBLAYOUT}"

        wm_config_template_copy keyboard "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp"
        sudo cp "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp" /etc/default/keyboard
        sudo chown root:root /etc/default/keyboard
        rm "${WM_CFG_SESSION_STORAGE_PATH}/keyboard.tmp"

        sudo udevadm trigger --subsystem-match=input --action=change
        wm_config_set_entry "WM_HOST_KEYBOARD_MANAGEMENT"  "false"
    fi
}


# host_support_management
#
# checks if a support key is present and establishes a tunnel to the target server
function host_support_management
{

    if [[ "${WM_HOST_SUPPORT_MANAGEMENT}" == "true" ]]
    then

        local _TARGET_TEMPLATE
        _TARGET_TEMPLATE=${WM_PHONE_TEMPLATE:-"wirepas-phone"}

        if [[ -f "${WM_SUPPORT_KEY}" ]]
        then
            web_notify "starting phone support to ${WM_SUPPORT_USERNAME}@${WM_SUPPORT_HOSTNAME}:${WM_SUPPORT_PORT} (key: ${WM_SUPPORT_KEY_PATH})"
            if [[ "${WM_SUPPORT_KEY}" != "${WM_SUPPORT_KEY_PATH}" ]]
            then
                sudo cp "${WM_SUPPORT_KEY}" "${WM_SUPPORT_KEY_PATH}"
            fi
            sudo chmod 400 "${WM_SUPPORT_KEY_PATH}"
            sudo chown "$(id -u):$(id -g)" "${WM_SUPPORT_KEY_PATH}"

            wm_config_template_copy "${_TARGET_TEMPLATE}" "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service"
            sudo cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service" /etc/systemd/system/wirepas-phone.service
            rm "${WM_CFG_SESSION_STORAGE_PATH}/wirepas-phone.service"

            sudo systemctl daemon-reload
            sudo systemctl enable wirepas-phone.service
            sudo systemctl start wirepas-phone.service
        else
            if [[ -f "/etc/systemd/system/wirepas-phone.service" ]]
            then
                web_notify "ensuring tunnel is down"
                sudo systemctl stop wirepas-phone.service
                sudo systemctl disable wirepas-phone.service
                sudo rm -f /etc/systemd/system/wirepas-phone.service
                sudo systemctl daemon-reload
            fi
        fi
    fi
}


# host_dbus_management
# Copies and configures dbus for access by the sink service
function host_dbus_management
{
    if [[ "${WM_HOST_DBUS_MANAGEMENT}" == "true" ]]
    then
        local _TARGET
        local _TARGET_TMP

        if [[ ! -f "/etc/dbus-1/system.d/${WM_GW_DBUS_CONF}" ]]
        then
            _TARGET="/etc/dbus-1/system.d/${WM_GW_DBUS_CONF}"
            _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/${WM_GW_DBUS_CONF}.tmp"

            wm_config_template_copy "${WM_GW_DBUS_CONF}" "${_TARGET_TMP}"
            sudo cp --no-preserve=mode,ownership "${_TARGET_TMP}" "${_TARGET}"
            rm "${_TARGET_TMP}"
        fi
    fi
}


