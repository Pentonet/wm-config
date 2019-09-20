#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

# wm_config_error
#
# prints out errors to the boot sector
function wm_config_error
{
    local _NOW
    _NOW=$(date)

    echo "${_NOW} : Aborting due to errexit on ${*}" > "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
    echo "==== journalctl ====" > "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
    env|grep WM >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    hostname -I >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        journalctl -u "${WM_SYSTEMD_UPDATER}" >> "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
        ${WM_CFG_SUDO} cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/*.log" "${WM_CFG_SETTINGS_PATH}/"
        ${WM_CFG_SUDO} rm -f "${WM_CFG_SESSION_STORAGE_PATH}/*.log" || true
    fi

    web_notify "Something went wrong! Please checks the logs from ${WM_CFG_SESSION_STORAGE_PATH}"
}

# wm_config_finish
#
# end of the script
function wm_config_finish
{

    date > "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    hostname -I >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    env|grep WM >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        journalctl -u "${WM_SYSTEMD_UPDATER}" > "${WM_CFG_SESSION_STORAGE_PATH}/journal.log"
        ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/env.log" "${WM_CFG_SETTINGS_PATH}/env.log"
        ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/journal.log" "${WM_CFG_SETTINGS_PATH}/journal.log"

        if [[ -f "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session" ]]
        then
            ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session" "${WM_CFG_SETTINGS_PATH}/session.log" || true
        fi
        ${WM_CFG_SUDO} rm -f  "${WM_CFG_SESSION_STORAGE_PATH}"/*.log || true
    fi

    web_notify "All done :sparkles:"
}
