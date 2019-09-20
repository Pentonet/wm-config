#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd


# wm_config_load_settings
#
# Sources the default and custom file to retrieve the parameter values
function wm_config_load_settings
{
    # load settings from environment files
    set -o allexport
    local _TARGET_TMP

    _TARGET_TMP="${WM_CFG_SESSION_STORAGE_PATH}/load.tmp"

    if [[ -f "${WM_CFG_SETTINGS_CUSTOM}" ]]
    then
        web_notify "read settings from ${WM_CFG_SETTINGS_CUSTOM}"
        cp "${WM_CFG_SETTINGS_CUSTOM}" "${_TARGET_TMP}"
        host_rm_win_linefeed "${_TARGET_TMP}" "${_TARGET_TMP}.load"
        source "${_TARGET_TMP}.load"

        rm "${_TARGET_TMP}"
        rm "${_TARGET_TMP}.load"
    else
        web_notify "could not find ${WM_CFG_SETTINGS_CUSTOM}"
        ${WM_CFG_SUDO} cp "${WM_CFG_INSTALL_PATH}/environment/custom.env" "${WM_CFG_SETTINGS_CUSTOM}"
    fi

    if [[ -f "${WM_CFG_SETTINGS_DEFAULT}" ]]
    then
        cp "${WM_CFG_SETTINGS_DEFAULT}" "${_TARGET_TMP}"
        host_rm_win_linefeed "${_TARGET_TMP}" "${_TARGET_TMP}.load"

        source "${WM_CFG_SETTINGS_DEFAULT}"

        rm "${_TARGET_TMP}"
        rm "${_TARGET_TMP}.load"

        web_notify "read settings from ${WM_CFG_SETTINGS_DEFAULT}"
    else
        web_notify "could not find ${WM_CFG_SETTINGS_DEFAULT}"
        exit 1
    fi
    set +o allexport
}


# wm_config_session_init
#
# Meant to initiate an execution round of the wm_config
function wm_config_session_init
{
    web_notify "delaying startup for ${WM_CFG_STARTUP_DELAY}"
    sleep "${WM_CFG_STARTUP_DELAY}"

    source "${WM_CFG_PYTHON_VIRTUAL_ENV}/bin/activate" || true
    web_notify "using python venv: $(which python)"

    rm -f "${WM_CFG_SESSION_STORAGE_PATH}"/*.log || true
    rm -f "${WM_CFG_SESSION_STORAGE_PATH}"/*.tmp || true
    rm -f "${WM_CFG_SESSION_STORAGE_PATH}"/*.load || true

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        host_sync_clock
        host_systemd_management
        host_set_keyboard_layout
        host_blacklist_ipv6
        host_upgrade
        host_install_dependencies
        host_tty_pseudo_names
        host_ssh_network_login
        host_expand_filesystem
        host_setup_user "${WM_HOST_USER_NAME}" "${WM_HOST_USER_PASSWORD}" "${WM_HOST_USER_PPKI}"
        host_setup_hostname
        host_setup_wifi
        host_service_tunnel
        docker_cleanup
    else
        host_install_dependencies
    fi

    host_dbus_policies
    wm_config_update
}


# wm_config_session_end
#
# Meant to perform any operation prior the execution end
function wm_config_session_end
{
    :
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

        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership \
            "${WM_CFG_INSTALL_PATH}/bin/wm-config.sh" "${WM_CFG_ENTRYPOINT}"
        ${WM_CFG_SUDO} chmod +x "${WM_CFG_ENTRYPOINT}"
        ${WM_CFG_SUDO} chown root:root "${WM_CFG_ENTRYPOINT}"

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
    ${WM_CFG_SUDO} sed -i "/${_ENTRY}/d" "${WM_CFG_SETTINGS_CUSTOM}"
    # force it to false in custom
    cp "${WM_CFG_SETTINGS_CUSTOM}" "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"

    ${WM_CFG_SUDO} echo "${_ENTRY}=${_VALUE}" >> "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"
    ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp" "${WM_CFG_SETTINGS_CUSTOM}"

    rm "${WM_CFG_SESSION_STORAGE_PATH}/.custom.tmp"
}


# wm_config_template_copy
#
# copies and fills in the template
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
    rm -f "${_OUTPUT_PATH}" "${_OUTPUT_PATH}.tmp"
    ( echo "cat <<EOF ${_OPERATOR} ${_OUTPUT_PATH}" && \
      cat "${TEMPLATE}" && \
      echo "EOF" \
    ) > "${_OUTPUT_PATH}.tmp"
    . "${_OUTPUT_PATH}.tmp"
    rm "${_OUTPUT_PATH}.tmp"
}


# wm_config_template_append
# Evaluates the template but instead of overwriting the output the contents
# are appended to it
function wm_config_template_append
{
    # input name is basename
    TEMPLATE_NAME=${1:-"defaults"}
    OUTPUT_PATH=${2:-"template.output"}

    # if set, changes the output filename
    TEMPLATE=${WM_CFG_TEMPLATE_PATH}/${TEMPLATE_NAME}.template

    web_notify "appending to ${OUTPUT_PATH} definitions from ${TEMPLATE}"
    rm -f  "${OUTPUT_PATH}.tmp"
    ( echo "cat <<EOF >>${OUTPUT_PATH}" && \
      cat "${TEMPLATE}" && \
      echo "EOF" \
    ) > "${OUTPUT_PATH}.tmp"
    . "${OUTPUT_PATH}.tmp"
    rm "${OUTPUT_PATH}.tmp"
}



# call wm_config_main
function wm_config_main
{
    wm_config_load_settings

    web_notify ":wirepas:-config build - ${WM_CFG_VERSION}"
    web_notify "my known ips: $(hostname -I)"

    wm_config_parser "$@"
    wm_config_session_init

    docker_gateway

    wm_config_session_end

    exit "${?}"
}


