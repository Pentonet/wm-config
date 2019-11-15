#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd


# wm_config_load_settings
#
# Sources the default and custom file to retrieve the parameter values
function wm_config_load_settings
{

    if [[ -f "${WM_CFG_SETTINGS_CUSTOM}" ]]
    then
        web_notify "read settings from ${WM_CFG_SETTINGS_CUSTOM}"
        set -o allexport
        host_ensure_linux_lf "${WM_CFG_SETTINGS_CUSTOM}"
        source "${WM_CFG_SETTINGS_CUSTOM}"
        set +o allexport
    else
        web_notify "could not find ${WM_CFG_SETTINGS_CUSTOM}"
        mkdir -p "${WM_CFG_SETTINGS_CUSTOM}"
        cp "${WM_CFG_INSTALL_PATH}/environment/custom.env" "${WM_CFG_SETTINGS_CUSTOM}"
    fi

    if [[ -f "${WM_CFG_SETTINGS_DEFAULT}" ]]
    then
        web_notify "read settings from ${WM_CFG_SETTINGS_DEFAULT}"
        set -o allexport
        source "${WM_CFG_SETTINGS_DEFAULT}"
        set +o allexport
    else
        web_notify "could not find ${WM_CFG_SETTINGS_DEFAULT}"
        exit 1
    fi
}


# wm_config_feature_selection
#
# Handles the feature selection customization
function wm_config_feature_selection
{

    web_notify "read settings from ${WM_CFG_SETTINGS_DEFAULT}"
    set -o allexport
    source "${WM_CFG_INSTALL_PATH}/environment/feature.env"
    set +o allexport

    if [[ "${WM_CFG_FRAMEWORK_DEBUG}" == "true" ]]
    then
        echo "WM-CONFIG FEATURE SELECTION:"
        for key in $(env | grep WM_HOST_)
        do
            echo "$key" | awk -F"=" '{print $1 " enabled? " $2 ;}'
        done
    fi
}


# wm_config_session_init
#
# Meant to initiate an execution round of the wm_config
function wm_config_session_init
{
    if [[ -z "${WM_CFG_STARTUP_DELAY}" ]]
    then
        web_notify "delaying startup for ${WM_CFG_STARTUP_DELAY}"
        sleep "${WM_CFG_STARTUP_DELAY}"
    fi

    if [[ -d "${WM_CFG_PYTHON_VIRTUAL_ENV}" ]]
    then
        source "${WM_CFG_PYTHON_VIRTUAL_ENV}/bin/activate" || true
        web_notify "python virtual environment: $(command -v python)"
    else
        web_notify "using system's python environment: $(command -v python) (not found: ${WM_CFG_PYTHON_VIRTUAL_ENV})"
    fi

    rm -fr "${WM_CFG_SESSION_STORAGE_PATH}" || true
    mkdir -p "${WM_CFG_SESSION_STORAGE_PATH}" || true

    host_clock_management
    host_systemd_management
    host_keyboard_management
    host_ip_management
    host_dependency_management
    host_tty_management
    host_ssh_daemon_management
    host_filesystem_management
    host_user_management
    host_hostname_management
    host_wifi_management
    host_support_management
    host_dbus_management
    host_docker_daemon_management

    # framework updates and device enumeration
    wm_config_update
    wm_config_bitrate_configuration
    wm_config_device_enumeration
}


# wm_config_session_end
#
# Meant to perform any operation prior the execution end
function wm_config_session_end
{
    # exits the python venv
    deactivate || true
}

# wm_config_update
#
# update routine, which pull a docker container
# with the next release files
function wm_config_update
{

    if [[ "${WM_CFG_FRAMEWORK_UPDATE}" == "true" ]]
    then

        docker_fetch_settings
        web_notify "I am updating the base program and scheduling a job restart"

        sudo cp --no-preserve=mode,ownership \
            "${WM_CFG_INSTALL_PATH}/bin/wm-config.sh" "${WM_CFG_ENTRYPOINT}"
        sudo chmod +x "${WM_CFG_ENTRYPOINT}"
        sudo chown root:root "${WM_CFG_ENTRYPOINT}"

        wm_config_set_entry "WM_CFG_FRAMEWORK_UPDATE" "false"

        if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
        then
            host_reboot 0
            exit 0
        fi

    else
        web_notify "skipping update pull"
    fi

}

# wirepas_add_entry
#
# sets the input argument to false
function wm_config_set_entry
{
    local _ENTRY=${1}
    local _VALUE=${2:-}

    web_notify "set setting entry: ${_ENTRY}=${_VALUE}"
    sed -i "/${_ENTRY}/d" "${WM_CFG_SETTINGS_CUSTOM}"
    # force it to false in custom
    cp "${WM_CFG_SETTINGS_CUSTOM}" "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"

    echo "${_ENTRY}=${_VALUE}" >> "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"
    cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp" "${WM_CFG_SETTINGS_CUSTOM}"

    rm "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"
}


# wm_config_template_copy
#
# copies and fills in the template by default the target
# file is replace. Pass in an optional operator as a 3rd argument
function wm_config_template_copy
{
    # input name is basename
    _TEMPLATE_NAME=${1:-"defaults"}
    _OUTPUT_PATH=${2:-"template.output"}
    _OPERATOR=${3:-">"}

    # if set, changes the output filename
    mkdir -p "${WM_CFG_TEMPLATE_PATH}"

    TEMPLATE=${WM_CFG_TEMPLATE_PATH}/${_TEMPLATE_NAME}.template
    web_notify "generating ${_OUTPUT_PATH} based on ${TEMPLATE}"
    rm -f "${_OUTPUT_PATH}.tmp"
    ( echo "cat <<EOF ${_OPERATOR} ${_OUTPUT_PATH}" && \
      cat "${TEMPLATE}" && \
      echo "EOF" \
    ) > "${_OUTPUT_PATH}.tmp"
    . "${_OUTPUT_PATH}.tmp"
    rm "${_OUTPUT_PATH}.tmp"
}


# wm_config_bitrate_configuration
#
# creates a bitrate list to be index by the device id.
#
function wm_config_bitrate_configuration
{
    export WM_GW_SINK_BITRATE_CONFIGURATION

    # create default bitrate array
    if [[ -z "${WM_GW_SINK_BITRATE_CONFIGURATION}" ]]
    then
        _SINK_BITRATE=()
        for _ in $(seq 0 1 10)
        do
            _SINK_BITRATE+=( "125000" )
        done
    else
        _SINK_BITRATE=($(echo "${WM_GW_SINK_BITRATE_CONFIGURATION}" | tr " " "\\n"))
    fi

    WM_GW_SINK_BITRATE_CONFIGURATION="${_SINK_BITRATE}"
}

# wm_config_device_enumeration
#
# creates a list of tty ports. If they are blacklisted
# the ports wont be added to the list.
#
function wm_config_device_enumeration
{
    export WM_GW_SINK_LIST
    WM_GW_SINK_LIST=( )

    local _SINK_ENUMERATION_PATTERN
    local _SINK_ENUMERATION_IGNORE

    local _DEVICE
    local _BLACKLISTED

    # multi sink support
    if [[ "${WM_GW_SINK_ENUMERATION}" == "true" ]]
    then
        _SINK_ENUMERATION_PATTERN=($(echo "${WM_GW_SINK_PORT_RULE}" | tr " " "\\n"))
        for _DEVICE in "${_SINK_ENUMERATION_PATTERN[@]}"
        do
            if [[ -z "${_DEVICE}" || "${_DEVICE}" == *"*"* ]]
            then
                web_notify "Could not find any device under ${_DEVICE}"
                continue
            fi

            if [[ ! -z "${WM_GW_SINK_BLACKLIST}" ]]
            then
                _SINK_ENUMERATION_IGNORE=($(echo "${WM_GW_SINK_BLACKLIST}" | tr " " "\\n"))

                for _BLACKLISTED in "${_SINK_ENUMERATION_IGNORE[@]}"
                do
                    if [[ "${_BLACKLISTED}" == "${_DEVICE}" ]]
                    then
                        web_notify "Device is blacklisted, skipping it (list=${_BLACKLISTED} == device=${_DEVICE})"
                        break
                    fi
                done
                continue
            fi
            WM_GW_SINK_LIST+=("${_DEVICE}")
        done
    else
        web_notify "skipping device enumeration - setting sink port to ${WM_GW_SINK_UART_PORT}"
        WM_GW_SINK_LIST=( "${WM_GW_SINK_UART_PORT}" )
    fi
}


# call wm_config_main
function wm_config_main
{
    wm_config_load_settings
    wm_config_feature_selection

    web_notify ":wirepas:-config ${WM_CFG_VERSION}/${WM_CFG_HOST_ARCH}"
    web_notify "ip addresses: $(hostname -I)"

    wm_config_parser "$@"
    wm_config_session_init
    wm_config_session_main
    wm_config_session_end

    exit "${?}"
}


