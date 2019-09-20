#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

set -o nounset
set -o errexit
set -o errtrace


##
## @brief      help text
##
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


##
## @brief      Parses input to change script behavior
##
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
            wm_cfg_setup_clean_files
            exit 0
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


##
## @brief      Default values
##
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

    WM_SETUP_SKIP_CALL=false

    WM_CFG_VERSION="2.0.0"

    WM_CFG_TARGETS=( ./bin/*.sh )
    WM_SETUP_TAR_DIR="."
    WM_SETUP_TAR_NAME="wmconfig.tar.gz"
    WM_SETUP_TAR_OUTPUT_PATH="deliverable"
    WM_SETUP_TAR_EXCLUDES=".tarignore"

    WM_CFG_ENTRYPOINT_PATH=${HOME}/.local/bin
    WM_CFG_INSTALL_PATH=${HOME}/.local/wirepas/wm-config
    WM_CFG_EXEC_NAME="wm-config"


    if [[ "${WM_SETUP_WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        WM_CFG_SETTINGS_PATH=${WM_CFG_SETTINGS_PATH:-"/boot/wirepas"}
        WM_CFG_SUDO=${WM_CFG_SUDO:-"sudo"}
    else
        WM_CFG_SETTINGS_PATH=${WM_CFG_SETTINGS_PATH:-"${HOME}/wirepas/wm-config"}
        WM_CFG_SUDO=${WM_CFG_SUDO:-}
    fi

    export PATH=${PATH}:${HOME}/.local/bin/

}

##
## @brief      Obtains platform details such as architecture and model
##
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


##
## @brief      Removes any existing wm-config files and entrypoint
##
function wm_cfg_setup_clean_files
{
    echo "Removing wm-config files"

    if [[ -d "${WM_SETUP_TAR_OUTPUT_PATH}/" ]]
    then
        ${WM_CFG_SUDO} rm -vrf "${WM_SETUP_TAR_OUTPUT_PATH}/"
    fi

    if [[ -d "${WM_CFG_INSTALL_PATH}/" ]]
    then
        ${WM_CFG_SUDO} rm -vrf "${WM_CFG_INSTALL_PATH}"
    fi

    if [[ -f "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME}" ]]
    then
        ${WM_CFG_SUDO} rm -vrf "${WM_CFG_ENTRYPOINT_PATH}/${WM_CFG_EXEC_NAME}"
    fi
}


##
## @brief      Logic to use when creating a bundle for installation
##
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

##
## @brief      Checks if there is a tar bundle and extracts its contents
##
##
function wm_cfg_setup_unpack
{
    if [[ -f "${HOME}/${WM_SETUP_TAR_NAME}" ]]
    then
        mkdir -pv "${WM_CFG_INSTALL_PATH}"
        cp "${HOME}/${WM_SETUP_TAR_NAME}" "${WM_CFG_INSTALL_PATH}"
        rm "${HOME}/${WM_SETUP_TAR_NAME}"
        cd "${WM_CFG_INSTALL_PATH}"
        tar -xvzf "${WM_CFG_INSTALL_PATH}/${WM_SETUP_TAR_NAME}"
    fi
}


##
## @brief      copies the wmconfig executable to the system level executable
##
##             The function attempts to source the path based on the tar
##             presence. If it is not present then it assumes it is
##             available in the bin folder where the executable has
##             been placed.
##
function wm_cfg_setup_wm_config
{
    local _TARGET
    local _IS_CLONE

    _TARGET=${WM_CFG_INSTALL_PATH}/bin/wm-config.sh
    _IS_CLONE=false

    if [[ -d ".git/" ]]
    then
        _TARGET="$(pwd)/bin/wm-config.sh"
        _IS_CLONE=true

        echo "found a git folder, setting copy target as ${_TARGET}"

        export WM_CFG_VERSION=$(git log -n 1 --oneline --format=%h)
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

    export PATH="${PATH}:/home/${USER}/.local/bin"

    if [[ "${_IS_CLONE}" == "true" ]]
    then
        wm_cfg_setup_restore_version_id "${WM_CFG_TARGETS[@]}"
    fi

}

##
## @brief      Replaces the build version strings in the main script file
##
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

##
## @brief      Checkout any changes made to target files
##
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

##
## @brief      Copies a custom environment into the entrypoint folder
##
##             This function looks up for any custom file in the home
##             folder and copies it over to the defined entrypoint.
##
function wm_cfg_setup_copy_custom_env
{
    local _CFILE

    _CFILE=${1:-"${HOME}/custom.env"}

    if [[ -f "${_CFILE}" ]]
    then
        echo "copying custom file: ${_CFILE}"
        ${WM_CFG_SUDO} mkdir -vp "${WM_CFG_SETTINGS_PATH}"
        ${WM_CFG_SUDO} mv -v "${_CFILE}" \
                             "${WM_CFG_SETTINGS_PATH}/custom.env"
    fi
}

##
## @brief      Checks if there are changes to be saved
##
function repo_has_changes()
{

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
}





##
## @brief      Logic to use when installing wm-config
##
function _install
{
    wm_cfg_setup_clean_files
    wm_cfg_setup_unpack
    wm_cfg_setup_copy_custom_env
    wm_cfg_setup_wm_config
}


##
## @brief      The main function
##
function _main
{
    _defaults

    repo_has_changes

    wm_cfg_setup_parser "${@}"
    _install

    if [[ "${WM_SETUP_SKIP_CALL}" == "false" ]]
    then
        # execute
        echo "calling wm-config"
        wm-config
    fi

    exit 0
}


_main "${@}"

