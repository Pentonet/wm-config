#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

set -o nounset
set -o errexit
set -o errtrace


## wm_cfg_requirements
##
## requirements to keep executing setup
function wm_cfg_requirements
{
    if [[ ! -f "${HOME}/${WM_SETUP_TAR_NAME}" && ! -d .git ]]
    then
        echo "Please clone the repo or drop a packed archive under ${HOME}/${WM_SETUP_TAR_NAME}"
        exit 1
    fi

    if [[ -d .git ]]
    then
        if [[ ! -z "$(git status --porcelain)" ]]
        then
            echo "Please commit or stash your changes before packing or installing!"
            echo "run this command to store your changes: \$ git stash "
            echo "run this command to drop: \$ git checkout . "
            exit 1
        fi
    fi

    if ! command -v rsync  >/dev/null
    then
        echo "Installing: rsync..."
        sudo apt-get install rsync -y
    fi

    if ! command -v curl  >/dev/null
    then
        echo "Installing: curl..."
        sudo apt-get install curl -y
    fi
}


## _help
##
## outputs the setup's help text
function _help
{
    local _ME
    _ME=$(basename "${0}")
    cat <<HEREDOC
Wirepas host configurator setup (${WM_CFG_VERSION})

Host details discovered by the setup:
    arch                        ${WM_SETUP_HOST_ARCH}
    model                       ${WM_SETUP_WM_CFG_HOST_MODEL}
    is_rpi                      ${WM_SETUP_WM_CFG_HOST_IS_RPI}

Usage:
    ${_ME} [<Options>]
    ${_ME} -h | --help

Options:
    --help                      Show this screen
    --debug                     Prints all the WM_ environment parameters and enables call trace for the shell

    --skip-call                 Move services to start/stop state (default: ${WM_SETUP_SKIP_CALL})

    --pack                      Creates a bundle for sharing across multiple hosts (${WM_SETUP_TAR_OUTPUT_PATH}/${WM_SETUP_TAR_NAME})

    --clean                     Removes wm-config files and entrypoints (this is not a full uninstall)

HEREDOC
}


## wm_cfg_setup_parser
##
## parses input to change script behavior
function wm_cfg_setup_parser
{
    # Gather commands
    while (( "${#}" ))
    do
        case "${1}" in

            --skip-call)
            WM_SETUP_SKIP_CALL=true
            shift
            ;;

            --pack)
            wm_cfg_setup_pack
            exit 0
            ;;

            --clean)
            wm_cfg_setup_cleanup
            exit 0
            ;;

            --uninstall)
            wm_cfg_uninstall
            exit 0
            ;;

            --interactive)
            wm_cfg_setup_ui
            shift
            ;;

            --debug)
            env |grep "WM_"
            set -x
            shift
            ;;

            --help)
            _help
            exit 1
            ;;

            *) # unsupported flags
            echo "unknown option: ${1}"
            _help
            exit 1
            ;;
        esac
    done
}


## _defaults
##
## default values, such as exec and settings path
function _defaults
{

    _get_platform

    export WM_CFG_VERSION
    export TARGETS
    export WM_SETUP_TAR_DIR
    export WM_SETUP_TAR_NAME
    export WM_SETUP_TAR_OUTPUT_PATH
    export WM_SETUP_TAR_EXCLUDES
    export WM_CFG_ENTRYPOINT_PATH
    export WM_CFG_INSTALL_PATH
    export WM_CFG_SETTINGS_PATH
    export WM_CFG_EXEC_NAME
    export WM_CFG_UNINSTALL
    export PATH

    WM_SETUP_SKIP_CALL=false
    WM_CFG_VERSION="2.0.2"

    USER_SETTINGS_CUSTOM="${HOME}/custom.env"

    WM_CFG_TARGETS=( ./bin/*.sh )
    WM_SETUP_TAR_DIR="."
    WM_SETUP_TAR_NAME="wmconfig.tar.gz"
    WM_SETUP_TAR_OUTPUT_PATH="deliverable"
    WM_SETUP_TAR_EXCLUDES=".tarignore"

    WM_CFG_ENTRYPOINT_PATH="${HOME}/.local/bin"
    WM_CFG_INSTALL_PATH="${HOME}/.local/wirepas/wm-config"
    WM_CFG_PATH_SETTINGS="${WM_CFG_INSTALL_PATH}/environment/path.env"
    WM_CFG_SETTINGS_DEFAULT="${WM_CFG_INSTALL_PATH}/environment/default.env"

    WM_CFG_EXEC_NAME=wm-config
    WM_CFG_UNINSTALL=false
    WM_CFG_SETTINGS_PATH=${WM_CFG_SETTINGS_PATH:-"${HOME}/wirepas/wm-config"}

    PATH="${PATH}:${HOME}/.local/bin/"
}

## _get_platform
##
##  obtains platform details such as architecture and model
function _get_platform()
{

    export WM_SETUP_WM_CFG_HOST_IS_RPI
    export WM_SETUP_WM_CFG_HOST_MODEL
    export WM_SETUP_HOST_ARCH

    local _DEVICE_TREE_MODEL

    _DEVICE_TREE_MODEL="/proc/device-tree/model"

    WM_SETUP_WM_CFG_HOST_IS_RPI="false"
    WM_SETUP_WM_CFG_HOST_MODEL="unknown"

    if [[ -f "${_DEVICE_TREE_MODEL}" ]]
    then
        WM_SETUP_WM_CFG_HOST_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    fi

    if [[ "${WM_SETUP_WM_CFG_HOST_MODEL}" == *"Raspberry"* ]]
    then
        WM_SETUP_WM_CFG_HOST_IS_RPI="true"
    fi

    WM_SETUP_HOST_ARCH=$(uname -m)
}

## _dockerhub_tags
##
## fetches the docker hub tags for a given repo/image
function _dockerhub_tags
{
    export DOCKERHUB_TAGS
    local DOCKERHUB_IMAGE
    DOCKERHUB_IMAGE="$1"
    if command -v curl >/dev/null
    then
        DOCKERHUB_TAGS=$(curl -s -q https://registry.hub.docker.com/v1/repositories/"${DOCKERHUB_IMAGE}"/tags | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}')
    fi
}

## _env_to_file
##
## takes an array of environment variables and sources them into a file
function _env_to_file
{
    local _INPUT
    local _OUTPUT

    _INPUT="${1}"
    _OUTPUT="${2}"

    IFS=' ' read -r -a evar <<< "${_INPUT}"
    for var in "${evar[@]}"; do
        if [[ "${!var}" ]]
        then
            echo "$var=${!var}" >> "${_OUTPUT}"
        fi
    done
}

## wm_cfg_setup_ui
##
## retrieves settings from the user
function wm_cfg_setup_ui()
{
    local WM_SERVICES_MQTT_HOSTNAME
    local WM_SERVICES_MQTT_USERNAME
    local WM_SERVICES_MQTT_PASSWORD
    local WM_SERVICES_MQTT_PORT
    local WM_SERVICES_ALLOW_UNSECURE
    local WM_GW_VERSION

    read -ren 253 -p "What is the ip or dns name of your MQTT broker? [ENTER]: " WM_SERVICES_MQTT_HOSTNAME
    read -ren 100 -p "What is MQTT user? [ENTER]: " WM_SERVICES_MQTT_USERNAME
    read -ren 100 -p "What is the password for your MQTT user, ${WM_SERVICES_MQTT_USERNAME}? [ENTER]: " WM_SERVICES_MQTT_PASSWORD
    read -ren 10 -p "On which port of ${WM_SERVICES_MQTT_HOSTNAME} do you want to connect to? [ENTER]: " WM_SERVICES_MQTT_PORT

    if [[ "${WM_SERVICES_MQTT_HOSTNAME}" == localhost
        || "${WM_SERVICES_MQTT_HOSTNAME}" == 0.0.0.0
        || "${WM_SERVICES_MQTT_HOSTNAME}" == 127.0.0.1
        || "${WM_SERVICES_MQTT_HOSTNAME}" == "::"
        || "${WM_SERVICES_MQTT_PORT}" == "1883" ]]
    then
        echo "It seems you're connecting to a local broker..."
        read -ren 5 -p "Have you installed a broker locally? [yes|no]: " question
        if [[ "${question}" == *"y"* ]]
        then
            read -ren 5 -p "Are you trying to connect without security? [yes|no]: " question
            if [[ "${question}" == "y"* ]]
            then
                WM_SERVICES_ALLOW_UNSECURE="true"
            fi
        else
            echo "Please ensure you have a local mqtt broker installed before starting wm-config"
            echo "For more information refer to: https://github.com/wirepas/tutorials"
        fi
    fi

    _dockerhub_tags "wirepas/gateway"
    if [[ "${DOCKERHUB_TAGS}" ]]
    then
        echo "Available versions for wirepas/gateway: "

        while read -r tag
        do
            echo " --> ${tag}"
        done <<< "${DOCKERHUB_TAGS}"
    fi
    read -ren 100 -p "Which gateway version would you like to use? [ENTER]: " WM_GW_VERSION

    echo "This should be enough to get you started!"
    echo "Creating file under: ${USER_SETTINGS_CUSTOM}..."

    echo "# Copyright 2019 Wirepas Ltd" > "${USER_SETTINGS_CUSTOM}"
    echo "# WM-CONFIG interactive custom.env generator" >> "${USER_SETTINGS_CUSTOM}"

    elist="${!WM_SERVICES_@}"
    _env_to_file "${elist[@]}" "${USER_SETTINGS_CUSTOM}"

    elist="${!WM_GW_@}"
    _env_to_file "${!WM_GW_@}" "${USER_SETTINGS_CUSTOM}"
}



## wm_cfg_setup_cleanup
##
## removes any existing wm-config files and entrypoint
function wm_cfg_setup_cleanup
{
    echo "Removing wm-config files"

    if [[ -d "${WM_SETUP_TAR_OUTPUT_PATH}/" ]]
    then
        rm -vrf "${WM_SETUP_TAR_OUTPUT_PATH:?}"
    fi

    if [[ -d "${WM_CFG_INSTALL_PATH}/" ]]
    then
        rm -vrf "${WM_CFG_INSTALL_PATH:?}"
    fi

    if [[ -f "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME}" ]]
    then
        rm -vrf "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME:?}"
    fi
}



## wm_cfg_uninstall
##
## removes all system files installed by the framework
function wm_cfg_uninstall
{
    if [[ -f "${WM_CFG_SETTINGS_DEFAULT}" ]]
    then
        # load defaults from installation prior to uninstall
        set -o allexport
        source "${WM_CFG_PATH_SETTINGS}"
        source "${WM_CFG_SETTINGS_DEFAULT}"
        set +o allexport

        if [[ -f "/etc/dbus-1/system.d/${WM_GW_DBUS_CONF}" ]]
        then
            sudo rm -vf /etc/dbus-1/system.d/com.wirepas.sink.conf
        fi

        if [[ -f "/etc/udev/rules.d/${WM_HOST_TTY_SIMLINK_FILENAME}" ]]
        then
            sudo rm -vf "/etc/udev/rules.d/${WM_HOST_TTY_SIMLINK_FILENAME}"
        fi

        if [[ -d "${WM_CFG_SETTINGS_PATH}" ]]
        then
            rm -vfr "${WM_CFG_SETTINGS_PATH:-?}"
        fi

        if [[ -d "${WM_CFG_PYTHON_VIRTUAL_ENV}" ]]
        then
            rm -vfr "${WM_CFG_PYTHON_VIRTUAL_ENV:-?}"
        fi

        # v1 RPi entrypoint
        if [[ -f "/usr/local/bin/wm-config" ]]
        then
            rm -vf "/usr/local/bin/wm-config"
        fi
    fi

    wm_cfg_setup_cleanup
}


## wm_cfg_setup_pack
##
## logic to use when creating a bundle for installation
function wm_cfg_setup_pack
{
    echo "Making tar archive"
    mkdir -vp "${WM_SETUP_TAR_OUTPUT_PATH}"
    wm_cfg_setup_set_version_number "${WM_CFG_TARGETS[@]}"
    tar -zcvf "${WM_SETUP_TAR_OUTPUT_PATH}/${WM_SETUP_TAR_NAME}" \
                --exclude-ignore "${WM_SETUP_TAR_EXCLUDES}" \
                -C "${WM_SETUP_TAR_DIR}" .
    wm_cfg_setup_restore_version_id "${WM_CFG_TARGETS[@]}"
}

## wm_cfg_setup_unpack
##
## checks if there is a tar bundle and extracts its contents
function wm_cfg_setup_unpack
{
    if [[ -f "${HOME}/${WM_SETUP_TAR_NAME}" ]]
    then
        mkdir -pv "${WM_CFG_INSTALL_PATH}"
        cp "${HOME}/${WM_SETUP_TAR_NAME}" "${WM_CFG_INSTALL_PATH}"
        rm "${HOME}/${WM_SETUP_TAR_NAME:?}"
        cd "${WM_CFG_INSTALL_PATH}"
        tar -xvzf "${WM_CFG_INSTALL_PATH}/${WM_SETUP_TAR_NAME}"
    fi
}


## wm_cfg_setup_wm_config
##
## copies the wmconfig executable to the system level executable
function wm_cfg_setup_wm_config
{
    export WM_CFG_VERSION
    export PATH

    local _TARGET
    local _IS_CLONE

    _TARGET=${WM_CFG_INSTALL_PATH}/bin/wm-config.sh
    _IS_CLONE=false

    if [[ -d ".git/" ]]
    then
        _TARGET="$(pwd)/bin/wm-config.sh"
        _IS_CLONE=true

        echo "found a git folder, setting copy target as ${_TARGET}"

        WM_CFG_VERSION=$(git log -n 1 --oneline --format=%h)
        wm_cfg_setup_set_version_number "${WM_CFG_TARGETS[@]}"
        echo "setting up ${WM_CFG_INSTALL_PATH}"
        mkdir -pv "${WM_CFG_INSTALL_PATH}"
        rsync -a  . "${WM_CFG_INSTALL_PATH}" --exclude-from .tarignore
    fi

    # copy and set permissions
    echo "installing ${WM_CFG_EXEC_NAME} under ${WM_CFG_ENTRYPOINT_PATH}"
    mkdir -vp "${WM_CFG_ENTRYPOINT_PATH}" || true
    cp -v --no-preserve=mode,ownership "${_TARGET}" "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME}"
    chmod +x "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME}"

    PATH="${PATH}:/home/${USER}/.local/bin"

    if [[ "${_IS_CLONE}" == "true" ]]
    then
        wm_cfg_setup_restore_version_id "${WM_CFG_TARGETS[@]}"
    fi

}

## wm_cfg_setup_set_version_number
##
## replaces the build version strings in the main script file
function wm_cfg_setup_set_version_number
{
    local _TARGETS
    local _TARGET

    _TARGETS=("$@")

    # sets the hash if possible
    for _TARGET in "${_TARGETS[@]}";
    do
        echo "setting version ${WM_CFG_VERSION} --> ${_TARGET}"
        _TARGET_TMP=${_TARGET}.tmp

        cp "${_TARGET}" "${_TARGET_TMP}"
        sed -i "s/#FILLVERSION/$(date -u) - ${WM_CFG_VERSION}/g" "${_TARGET}"
    done
}

## wm_cfg_setup_restore_version_id
##
## checkout any changes made to target files
function wm_cfg_setup_restore_version_id
{
    local _TARGETS
    local _TARGET

    _TARGETS=("$@")

    for _TARGET in "${_TARGETS[@]}"
    do
        echo "reseting: ${_TARGET}"
        git checkout -- "${_TARGET}"
        rm -f "${_TARGET}.tmp" || true
    done


}

## wm_cfg_setup_copy_custom_env
##
## copies a custom environment into the entrypoint folder
function wm_cfg_setup_copy_custom_env
{
    mkdir -vp "${WM_CFG_SETTINGS_PATH}"

    if [[ -f "${USER_SETTINGS_CUSTOM}" ]]
    then
        echo "copying custom file: ${USER_SETTINGS_CUSTOM}"
        mv -v "${USER_SETTINGS_CUSTOM}" "${WM_CFG_SETTINGS_PATH}/custom.env"

    elif [[ ! -f "${WM_CFG_SETTINGS_PATH}/custom.env" && -f "${WM_CFG_INSTALL_PATH}/environment/custom.env" ]]
    then
        cp -v "${WM_CFG_INSTALL_PATH}/environment/custom.env" \
              "${WM_CFG_SETTINGS_PATH}/custom.env"
    fi

    if [[ -f "${WM_SETUP_WM_CFG_HOST_IS_RPI}" ]]
    then
        sudo mkdir -pv /boot/wirepas
    fi
}


## _main
##
## The main function
function _main
{
    _defaults

    wm_cfg_setup_parser "${@}"
    wm_cfg_requirements
    wm_cfg_setup_cleanup
    wm_cfg_setup_unpack
    wm_cfg_setup_copy_custom_env
    wm_cfg_setup_wm_config

    if [[ "${WM_SETUP_SKIP_CALL}" == "false" ]]
    then
        # execute
        echo "calling wm-config"
        wm-config
    fi

    exit 0
}


_main "${@}"

