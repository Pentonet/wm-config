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
        source "${_CFILE}" || true
    done

    trap 'wm_config_error "${BASH_SOURCE}:${LINENO} (rc: ${?})"' ERR
    trap 'wm_config_finish "${BASH_SOURCE}"' EXIT
}

function _defaults
{
    export WM_CFG_VERSION
    export WM_CFG_ENTRYPOINT
    export WM_CFG_INSTALL_PATH

    _get_platform

    WM_CFG_VERSION="#FILLVERSION"
    WM_CFG_ENTRYPOINT="${HOME}/.local/bin/wm-config"
    WM_CFG_INSTALL_PATH="${HOME}/.local/wirepas/wm-config"

    set -o allexport
    source "${WM_CFG_INSTALL_PATH}/environment/path.env"
    set +o allexport

    # create a symbolic link to the boot sector
    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        WM_CFG_SETTINGS_RPI_BOOT=${WM_CFG_SETTINGS_RPI_BOOT:-"/boot/wirepas/custom.env"}

        if [[ -f "${WM_CFG_SETTINGS_RPI_BOOT}" ]]
        then
            rm -fv "${WM_CFG_SETTINGS_CUSTOM}"
            sudo cp --no-preserve=mode,ownership "${WM_CFG_SETTINGS_RPI_BOOT}" "${WM_CFG_SETTINGS_CUSTOM}"
            sudo chown "$(id -u):$(id -g)" "${WM_CFG_SETTINGS_CUSTOM}"
        fi
    fi

    mkdir -p "${WM_CFG_UPDATE_PATH}"
    mkdir -p "${WM_CFG_HOST_DEPENDENCIES_PATH}"
    mkdir -p "${WM_CFG_TEMPLATE_PATH}"
    mkdir -p "${WM_CFG_SESSION_STORAGE_PATH}"

    if [[ -f "${WM_CFG_SETTINGS_CUSTOM}" ]]
    then
        touch "${WM_CFG_SETTINGS_CUSTOM}"
    fi
}

# call wm_config_main
function _main
{
    _defaults
    _import_modules
    wm_config_main "$@"
}

_main "$@"

