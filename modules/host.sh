#!/usr/bin/env bash
# Wirepas Oy
#
# functions to interact with the host system


# host_reboot
#
# performs a system reboot
function host_reboot
{
    MIN_TO_REBOOT=${1:-"${WM_CFG_REBOOT_DELAY}"}
    web_notify "device rebooting in +${MIN_TO_REBOOT}"
    sudo shutdown --reboot "+${MIN_TO_REBOOT}"
}


# host_upgrade
#
# Fetches updates from the package manager
function host_upgrade
{
    if [[ "${WM_CFG_HOST_UPGRADE}" == "true" ]]
    then
        web_notify "upgrading host packages"
        sudo apt-get update && sudo apt-get upgrade -y
        wirepas_remove_entry "WM_CFG_HOST_UPGRADE"
    fi
}

## host_rm_win_linefeed
function host_rm_win_linefeed
{
    INPUT=${1}
    OUTPUT=${2}

    tr -d '\15\32' < ${INPUT} > ${OUTPUT}
}

# host_install_dependencies
#
# Sources dependencies from the ENTRYPOINT partition
function host_install_dependencies
{
    if [[ "${WM_CFG_HOST_INSTALL_DEPENDENCIES}" == "true" ]]
    then

        if [[ -f ${WM_ENTRYPOINT_SETTINGS}/host_dependencies.sh ]]
        then
            web_notify "installing ${WM_ENTRYPOINT_SETTINGS}/host_dependencies.sh "

            sudo cp --no-preserve=mode,ownership \
                ${WM_ENTRYPOINT_SETTINGS}/host_dependencies.sh \
                ${WM_SERVICE_HOME}/host_dependencies.tmp

            host_rm_win_linefeed ${WM_SERVICE_HOME}/host_dependencies.tmp ${WM_SERVICE_HOME}/host_dependencies.sh

            chmod +x ${WM_SERVICE_HOME}/host_dependencies.sh
            sudo ${WM_SERVICE_HOME}/host_dependencies.sh || true
        fi

        if [[ -f ${WM_CFG_DEPENDENCIES_PATH}/host_dependencies.sh ]]
        then
            web_notify "installing ${WM_CFG_DEPENDENCIES_PATH}/host_dependencies.sh"
            chmod +x ${WM_CFG_DEPENDENCIES_PATH}/host_dependencies.sh
            sudo  ${WM_CFG_DEPENDENCIES_PATH}/host_dependencies.sh
        fi

        host_pip_install ${WM_ENTRYPOINT_SETTINGS}/requirements.txt
        host_pip_install ${WM_CFG_DEPENDENCIES_PATH}/requirements.txt

        export PATH=$PATH:/home/${USER}/.local/bin
        wirepas_remove_entry "WM_CFG_HOST_INSTALL_DEPENDENCIES"

        docker_add_user

        if [[ "${HOST_ARCHITECTURE}" == "armv7l" ]]
        then
            host_reboot 0
            exit 0
        else
            echo "a reboot is mandatory for your user to gain acces to the docker engine"
            exit 0
        fi

    else
        export PATH=$PATH:/home/${USER}/.local/bin
    fi
}


# host_pip_install
#
# installs requirements for python using pip
function host_pip_install
{
    _requirements=${1:-""}

    if [[ -f ${_requirements} ]]
    then
        web_notify "installing ${_requirements}"

        sudo cp --no-preserve=mode,ownership \
            ${_requirements} \
            ${WM_SERVICE_HOME}/requirements.tmp

        host_rm_win_linefeed ${WM_SERVICE_HOME}/requirements.tmp ${WM_SERVICE_HOME}/requirements.txt

        pip3 install --user -r ${WM_SERVICE_HOME}/requirements.txt
        echo "export PATH=$PATH:/home/${USER}/.local/bin" >> ~/.profile
    fi
}


# host_sync_clock
#
# forces a ntp sync by restarting the ntp service
function host_sync_clock
{
    web_notify "restarting systemd-timesyncd"
    sudo systemctl status systemd-timesyncd >> ${WM_SERVICE_HOME}/.wirepas_session || true
    sudo systemctl restart systemd-timesyncd  || true
}


# host_systemd_management
#
# starts or stops the wirepas updater
function host_systemd_management
{
    web_notify "reloading systemd services"

    if [[ "${WM_CFG_SYSTEMD_UPDATER_DISABLE}" == "true" ]]
    then
        web_notify "disabling wirepas-updater"

        sudo systemctl stop ${WM_CFG_SYSTEMD_UPDATER} || true
        sudo systemctl disable ${WM_CFG_SYSTEMD_UPDATER} || true
        wirepas_remove_entry "WM_CFG_SYSTEMD_UPDATER_DISABLE"
        exit 0
    fi

    if [[ "${WM_CFG_SYSTEMD_UPDATER_ENABLE}" == "true" ]]
    then
        _target="/etc/systemd/system/${WM_CFG_SYSTEMD_UPDATER}.service"
        _target_tmp="${WM_SERVICE_HOME}/${WM_CFG_SYSTEMD_UPDATER}.service.tmp"

        wirepas_template_copy ${WM_CFG_SYSTEMD_UPDATER} ${_target_tmp}
        sudo cp --no-preserve=mode,ownership ${_target_tmp} ${_target}
        rm ${_target_tmp}

        sudo systemctl daemon-reload
        sudo systemctl enable ${WM_CFG_SYSTEMD_UPDATER}

        wirepas_remove_entry "WM_CFG_SYSTEMD_UPDATER_ENABLE"
        host_schedule_future 1
    fi
}

# host_blacklist_ipv6
#
# blacklists ipv6 module and reboot the host
function host_blacklist_ipv6
{
    TARGET="/etc/modprobe.d/ipv6.conf"
    TEMPFILE=${WM_SERVICE_HOME}/ipv6.tmp

    if [[ "${WM_HOST_IPV6_DISABLE}" == "true" ]]
    then
        web_notify "blacklisting ipv6"

        sudo cp ${TARGET} ${TEMPFILE}
        sudo chown $(id -u):$(id -g) ${TEMPFILE}

        echo "alias ipv6 off" >> ${TEMPFILE}
        echo "options ipv6 disable_ipv6=1" >> ${TEMPFILE}
        echo "blacklist ipv6" >> ${TEMPFILE}

        sudo cp ${TEMPFILE} ${TARGET}
        sudo chown root:root ${TARGET}

        wirepas_remove_entry "WM_HOST_IPV6_DISABLE"

        host_reboot 0
        exit 0
    fi
}


# host_ssh_network_login
#
# sets the network logins for the main user
function host_ssh_network_login
{
    sudo touch /boot/ssh
    _services=( "${WM_HOST_AVAHI_SERVICES}" )
    echo "${_services}"
    for _service in ${_services}
    do
        web_notify "advertising avahi service: ${_service}"
        sudo cp ${_service} /etc/avahi/services/
    done

    sudo systemctl restart avahi-daemon.service

    if [[ "${WM_HOST_SSH_ENABLE_NETWORK_LOGIN}" == "true" ]]
    then
        sudo sed -i "s#PasswordAuthentication no#PasswordAuthentication yes#" /etc/ssh/sshd_config
    else
        _target="/etc/ssh/sshd_config"
        _target_tmp="${WM_SERVICE_HOME}/sshd_config.tmp"

        wirepas_template_copy sshd_config ${_target_tmp}
        sudo cp --no-preserve=mode,ownership ${_target_tmp} ${_target}
        rm ${_target_tmp}

        sudo sed -i "s#PasswordAuthentication yes#PasswordAuthentication no#" /etc/ssh/sshd_config
    fi

    sudo systemctl restart ssh
}


# host_rpi_expand_filesystem
#
# expands the filesystem
function host_expand_filesystem
{
    if [[ "${WM_RPI_EXPAND_FILESYSTEM}" == "true" ]] &&  [[ "${HOST_ARCHITECTURE}" == "armv7l" ]]
    then
        web_notify "expanding filesystem"
        wirepas_remove_entry "WM_RPI_EXPAND_FILESYSTEM"
        WM_RPI_EXPAND_FILESYSTEM=false

        sudo raspi-config --expand-rootfs

        web_notify "I am rebooting to expand the filesystem"
        host_reboot 0
        exit
    else
        echo "skipping file system increase"
    fi
}

# host_setup_hostname
#
# sets the system hostname
function host_setup_hostname
{
    CURRENT_HOSTNAME=$(hostname)
    if [[ ! -z ${WM_HOST_SET_HOSTNAME} ]] && [[ "${WM_HOST_SET_HOSTNAME}" != ${CURRENT_HOSTNAME} ]]
    then
        web_notify "making hostname change to ${WM_HOST_SET_HOSTNAME}"
        sudo sed -i "s/${CURRENT_HOSTNAME}/${WM_HOST_SET_HOSTNAME}/g" /etc/hostname
        sudo sed -i "s/${CURRENT_HOSTNAME}/${WM_HOST_SET_HOSTNAME}/g" /etc/hosts
        sudo hostnamectl set-hostname ${WM_HOST_SET_HOSTNAME}
        sudo systemctl restart avahi-daemon

    else
        echo "keeping hostname ${CURRENT_HOSTNAME}"
    fi
}

# host_setup_wifi
#
# Enables or disables the wifi interface
# An empty SSID or WM_WIFI_DISABLE to true will stop the wifi interface
function host_setup_wifi
{
    if [[ "${WM_WIFI_DISABLE}" != "true" ]] && [[ ! -z "${WM_WIFI_AP_SSID}" ]]
    then
        WM_WIFI_TEMPLATE=${WM_WIFI_TEMPLATE:-"wpa_supplicant"}

        web_notify "configuring WiFi client to: ${WM_WIFI_AP_SSID} / ${WM_WIFI_AP_PASSWORD}"

        wirepas_template_copy ${WM_WIFI_TEMPLATE} ${WM_SERVICE_HOME}/wpa_supplicant.conf
        sudo cp --no-preserve=mode,ownership  ${WM_SERVICE_HOME}/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
        sudo wpa_cli -i wlan0 reconfigure || true
        ifconfig wlan0 > ${WM_SERVICE_HOME}/.wlan0.tmp ||true

        sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/.wlan0.tmp ${WM_ENTRYPOINT_SETTINGS}/wlan0.log
        sudo rm ${WM_SERVICE_HOME}/.wlan0.tmp
        sudo rm ${WM_SERVICE_HOME}/wpa_supplicant.conf
    else
        web_notify "ensuring WiFi client is down"
        sudo ifdown wlan0 || true
    fi
}

# host_setup_user
#
# evaluates the user passwords and public keys
function host_setup_user
{
    SETUP_USER_NAME=${1:-}
    SETUP_USER_PWD=${2:-}
    SETUP_USER_PPKI=${3:-}

    SSH_FOLDER="/home/${SETUP_USER_NAME}/.ssh/"

    if [[ ! -z ${SETUP_USER_NAME} ]] && [[ ! -z ${SETUP_USER_PWD} ]]
    then
        web_notify "applying new password for ${SETUP_USER_NAME}:${SETUP_USER_PWD}"
        echo "${SETUP_USER_NAME}:${SETUP_USER_PWD}" | sudo chpasswd
    fi

    if [[ ! -z ${SETUP_USER_PPKI} ]] && [[ ! -z ${SETUP_USER_NAME} ]] && [[ ! -z ${SETUP_USER_PWD} ]]
    then
        if [[ ! -d /home/${SETUP_USER_NAME}/.ssh/ ]]
        then
            sudo mkdir -p ${SSH_FOLDER}
        fi

        if [[ ! -f /home/${SETUP_USER_NAME}/.ssh/authorized_keys ]]
        then
            sudo touch /home/${SETUP_USER_NAME}/.ssh/authorized_keys
        fi

        sudo cp /home/${SETUP_USER_NAME}/.ssh/authorized_keys ${WM_SERVICE_HOME}/.authorized_keys.tmp
        sudo chown ${USER}:${USER} ${WM_SERVICE_HOME}/.authorized_keys.tmp

        if grep -Fxq "${SETUP_USER_PPKI}" ${WM_SERVICE_HOME}/.authorized_keys.tmp
        then
            web_notify "ssh key already authorized"
        else
            web_notify "adding authorized ssh key: ${SETUP_USER_NAME}@${SETUP_USER_PPKI}"
            echo ${SETUP_USER_PPKI} > ${WM_SERVICE_HOME}/.authorization.tmp
            sudo cp ${WM_SERVICE_HOME}/.authorization.tmp /home/${SETUP_USER_NAME}/.ssh/authorized_keys
            sudo rm ${WM_SERVICE_HOME}/.authorization.tmp
            sudo rm ${WM_SERVICE_HOME}/.authorized_keys.tmp
        fi

        sudo chown -R ${SETUP_USER_NAME}:${SETUP_USER_NAME} ${SSH_FOLDER}
        sudo systemctl restart ssh.service || true
    fi

    set +x
}


# host_tty_pseudo_names
#
# sets custom tty names
function host_tty_pseudo_names
{
    web_notify "tty pseudonames ${WM_ENABLE_SERIAL_SYMLINKS} => ${WM_SERIAL_NICKNAME}"
    if [[ ${WM_ENABLE_SERIAL_SYMLINKS} == "true" ]]
    then

        _target="/etc/udev/rules.d/99-usb-serial.rules"
        _target_tmp="${WM_SERVICE_HOME}/99-usb-serial.rules.tmp"

        wirepas_template_copy 99-usb-serial ${_target_tmp}
        sudo cp --no-preserve=mode,ownership ${_target_tmp} ${_target}
        rm ${_target_tmp}

        if [[ ! -z ${WM_SERIAL_NICKNAME} ]]
        then
            sudo sed -i "s/SYMLINK+=\"ttyWM\"/SYMLINK+=\"${WM_SERIAL_NICKNAME}\"/" /etc/udev/rules.d/99-usb-serial.rules
        fi
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
        mkdir -p ${HOME}/.aws
        wirepas_template_copy aws_credentials ${HOME}/.aws/credentials
        wirepas_template_copy aws_config ${HOME}/.aws/config
    fi
}


# host_schedule_future
#
# Sechedules the daemon to restart in the future
function host_schedule_future
{
    web_notify "scheduling job restart and exitting"
    sudo systemctl daemon-reload
    sudo systemctl restart ${WM_CFG_SYSTEMD_UPDATER}
    exit 0
}


# host_set_keyboard_layout
#
# Defines the host keyboard model and options
function host_set_keyboard_layout
{

    if [[ "${WM_HOST_SET_KEYBOARD}" == "true" ]]
    then
        web_notify "setting keyboard layout to model->${WM_HOST_KEYBOARD_XKBMODEL} layout->${WM_HOST_KEYBOARD_XKBLAYOUT}"

        wirepas_template_copy keyboard ${WM_SERVICE_HOME}/keyboard.tmp
        sudo cp ${WM_SERVICE_HOME}/keyboard.tmp /etc/default/keyboard
        sudo chown root:root /etc/default/keyboard
        rm ${WM_SERVICE_HOME}/keyboard.tmp

        sudo udevadm trigger --subsystem-match=input --action=change
    fi
}


