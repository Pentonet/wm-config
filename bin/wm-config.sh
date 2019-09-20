#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

set -o nounset
set -o errexit
set -o errtrace

export DEFAULT_IFS
export SAFER_IFS
export IFS
export PATH

DEFAULT_IFS="${IFS}"
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"
PATH=$PATH:/home/${USER}/.local/bin

function _get_platform()
{
    export WM_CFG_HOST_ARCH
    export WM_CFG_HOST_MODEL
    export WM_CFG_HOST_IS_RPI

    local _DEVICE_TREE_MODEL

    WM_CFG_HOST_ARCH=$(uname -m)
    WM_CFG_HOST_IS_RPI="false"
    WM_CFG_HOST_MODEL="unknown"

    _DEVICE_TREE_MODEL="/proc/device-tree/model"

    if [[ -f "${_DEVICE_TREE_MODEL}" ]]
    then
        WM_CFG_HOST_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    fi

    if [[ "${WM_CFG_HOST_MODEL}" == *"Raspberry"* ]]
    then
        WM_CFG_HOST_IS_RPI="true"
    fi
}

# _import_modules
#
# fetch fucntions from the modules folder
function _import_modules
{
    local _CFILE
    for _CFILE in "${WM_CFG_INSTALL_PATH}"/modules/*.sh
    do
        echo "importing module ${_CFILE}"
        chmod +x "${_CFILE}" || true
        # shellcheck disable=SC1090
        set -o allexport
        source "${_CFILE}" || true
        set +o allexport
    done

    trap 'wm_config_error "${BASH_SOURCE}:${LINENO} (rc: ${?})"' ERR
    trap 'wm_config_finish "${BASH_SOURCE}"' EXIT
}


function _defaults
{
    export WM_CFG_VERSION
    export WM_CFG_ENTRYPOINT
    export WM_CFG_SETTINGS_PATH
    export WM_CFG_SETTINGS_DEFAULT
    export WM_CFG_SETTINGS_CUSTOM
    export WM_CFG_SUDO
    export WM_CFG_HOST_PATH
    export WM_CFG_UPDATE_PATH
    export WM_CFG_TEMPLATE_PATH
    export WM_CFG_GATEWAY_PATH

    _get_platform

    WM_CFG_VERSION="Fri 18 Oct 20:40:08 UTC 2019 - 6b28c3a"

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then

        WM_CFG_ENTRYPOINT=${WM_CFG_ENTRYPOINT:-${HOME}/.local/bin/wm-config}
        WM_CFG_INSTALL_PATH=${WM_CFG_INSTALL_PATH:-"${HOME}/.local/wirepas/wm-config"}
        WM_CFG_SETTINGS_DEFAULT=${WM_CFG_SETTINGS_DEFAULT:-"${WM_CFG_INSTALL_PATH}/environment/default.env"}

        WM_CFG_SETTINGS_PATH=${WM_CFG_SETTINGS_PATH:-"/boot/wirepas"}
        WM_CFG_SETTINGS_CUSTOM=${WM_CFG_SETTINGS_CUSTOM:-"${WM_CFG_SETTINGS_PATH}/custom.env"}
        WM_CFG_SUDO=${WM_CFG_SUDO:-"sudo"}
        WM_CFG_SESSION_STORAGE_PATH=${WM_CFG_SESSION_STORAGE_PATH:-"${HOME}/wirepas/.session"}
        WM_CFG_GATEWAY_PATH="${HOME}/wirepas/wm-config/lxgw"
    else
        WM_CFG_ENTRYPOINT=${WM_CFG_ENTRYPOINT:-${HOME}/.local/bin/wm-config}
        WM_CFG_INSTALL_PATH=${WM_CFG_INSTALL_PATH:-"${HOME}/.local/wirepas/wm-config"}
        WM_CFG_SETTINGS_DEFAULT=${WM_CFG_SETTINGS_DEFAULT:-"${WM_CFG_INSTALL_PATH}/environment/default.env"}

        WM_CFG_SETTINGS_PATH=${WM_CFG_SETTINGS_PATH:-"${HOME}/wirepas/wm-config"}
        WM_CFG_SETTINGS_CUSTOM=${WM_CFG_SETTINGS_CUSTOM:-"${WM_CFG_SETTINGS_PATH}/custom.env"}
        WM_CFG_SESSION_STORAGE_PATH=${WM_CFG_SESSION_STORAGE_PATH:-"${WM_CFG_SETTINGS_PATH}/.session"}

        WM_CFG_GATEWAY_PATH="${WM_CFG_SETTINGS_PATH}/lxgw"

        WM_CFG_SUDO=${WM_CFG_SUDO:-""}
    fi

    WM_CFG_HOST_PATH=${WM_CFG_HOST_PATH:-"${WM_CFG_INSTALL_PATH}/host"}
    WM_CFG_UPDATE_PATH=${WM_CFG_UPDATE_PATH:-"${WM_CFG_INSTALL_PATH}/update"}
    WM_CFG_TEMPLATE_PATH=${WM_CFG_TEMPLATE_PATH:-"${WM_CFG_INSTALL_PATH}/templates"}

    mkdir -p "${WM_CFG_UPDATE_PATH}"
    mkdir -p "${WM_CFG_HOST_PATH}"
    mkdir -p "${WM_CFG_TEMPLATE_PATH}"
    mkdir -p "${WM_CFG_SESSION_STORAGE_PATH}"
}

# call wm_config_main
function _main
{
    _defaults
    _import_modules
    wm_config_main "$@"
}

_main "$@"

