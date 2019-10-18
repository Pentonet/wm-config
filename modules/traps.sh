#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

# wm_config_error
#
# prints out errors to the boot sector
function wm_config_error
{
    set +e
    local _NOW
    _NOW=$(date)

    echo "${_NOW} : Aborting due to errexit on ${*}" > "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
    echo "==== journalctl ====" > "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
    env | grep WM >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    hostname -I >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        sudo mkdir -p "/boot/wirepas/"
        journalctl -u "${WM_SYSTEMD_UPDATER}" >> "${WM_CFG_SESSION_STORAGE_PATH}/error.log"
        sudo cp --no-preserve=mode,ownership "${WM_CFG_SESSION_STORAGE_PATH}/*.log" "/boot/wirepas"
    fi

    web_notify "Something went wrong! Please checks the logs from ${WM_CFG_SESSION_STORAGE_PATH}"
}

# wm_config_finish
#
# end of the script
function wm_config_finish
{
    set +e
    date > "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    hostname -I >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
    env|grep WM >> "${WM_CFG_SESSION_STORAGE_PATH}/env.log"

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        sudo mkdir -p "/boot/wirepas/"
        journalctl -u "${WM_SYSTEMD_UPDATER}" > "${WM_CFG_SESSION_STORAGE_PATH}/journal.log"
        sudo cp "${WM_CFG_SESSION_STORAGE_PATH}/env.log" "/boot/wirepas/env.log"
        sudo cp "${WM_CFG_SESSION_STORAGE_PATH}/journal.log" "/boot/wirepas/journal.log"

        if [[ -f "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session" ]]
        then
            sudo cp "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session" "/boot/wirepas/session.log"
        fi
    fi

    web_notify "All done :sparkles:"
}
