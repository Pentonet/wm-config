#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd
#
# functions to interact with docker

#shellcheck disable=SC1090

# docker_add_user
#
# adds user to docker group
function docker_add_user
{
    local _USERNAME

    _USERNAME=${1:-"${USER}"}
    if ! groups "${_USERNAME}" | grep &>/dev/null '\bdocker\b'
    then
        web_notify "adding user to docker group"
        ${WM_CFG_SUDO} usermod -aG docker "${_USERNAME}" || true
    fi
}

# docker_login
#
# logins with given user and password credentials
function docker_login
{

    if [[ ! -z "${WM_DOCKER_USERNAME}" && ! -z "${WM_DOCKER_PASSWORD}" ]]
    then
        web_notify "Setting docker credentials for ${WM_DOCKER_USERNAME}"
        ${WM_CFG_SUDO} docker login --username "${WM_DOCKER_USERNAME}" --password "${WM_DOCKER_PASSWORD}"
    fi
}


# docker_service_status
#
# waits for a given amount of time and prints container status
function docker_service_status
{
    web_notify "presenting service status in +${WM_DOCKER_STATUS_DELAY}"
    sleep "${WM_DOCKER_STATUS_DELAY}"

    ${WM_CFG_SUDO} docker ps -a >> "${WM_CFG_INSTALL_PATH}/.wirepas_session"
    #shellcheck disable=SC2046
    web_notify "$(printf "%s\\n" $(${WM_CFG_SUDO} docker ps --format '{{.Names}} : {{.Status}} : {{.Image}} '))"
}

# docker_service_logs
#
# waits for a given amount of time and prints container status
function docker_service_logs
{
    local _COMPOSE_PATH
    _COMPOSE_PATH=${1:-"${WM_CFG_GATEWAY_PATH}/docker-compose.yml"}

    web_notify "$(docker-compose -f "${_COMPOSE_PATH}" logs -t)"
}



# docker_cleanup management
#
# cleans up dangling images
function docker_cleanup
{
    local _WIPE_ALL

    _WIPE_ALL=${1:-"${WM_DOCKER_CLEANUP}"}

    if [[ "${_WIPE_ALL}" == "true" ]]
    then
        #Necessary to allow successful completion on Raspbian buster see #25
        set +e
        web_notify "removing all containers"
        #shellcheck disable=SC2046
        ${WM_CFG_SUDO} docker rm -f $( ${WM_CFG_SUDO} docker ps -aq) || true
        wm_config_set_entry "WM_DOCKER_CLEANUP" "false"
        set -e
    fi

    # Necessary to allow successful completion on Raspbian buster see #25
    set +e
    web_notify "pruning all _unused_ docker elements"
    ${WM_CFG_SUDO} docker system prune --all --force || true
    set -e

}


# docker_stop
#
# stop the service execution
function docker_stop
{
    local _COMPOSE_PATH
    _COMPOSE_PATH=${1:-"${WM_CFG_GATEWAY_PATH}/docker-compose.yml"}

    web_notify "stopping services in ${_COMPOSE_PATH}"
    docker-compose -f "${_COMPOSE_PATH}" down
}



# docker_redeploy
#
# pulls and recreates the services
function docker_redeploy
{
    local _COMPOSE_PATH
    local _AS_DAEMON
    local _FORCE_RECREATE
    local _cmd

    _COMPOSE_PATH=${1:-"${WM_CFG_GATEWAY_PATH}/docker-compose.yml"}
    _AS_DAEMON=${2:-"true"}
    _FORCE_RECREATE=${3:-"${WM_DOCKER_FORCE_RECREATE}"}

    env | grep WM_ > "${WM_GW_SERVICES_ENV_FILE}"

    docker_login
    _cmd="yes | ${WM_CFG_SUDO} docker-compose -f ${_COMPOSE_PATH} pull --ignore-pull-failures || true"
    web_notify "pulling updates to service images: ${_cmd}"
    eval "${_cmd}"

    if [[ "${_FORCE_RECREATE}" == "true" ]]
    then
        FLAG_RECREATE="--force-recreate"
    else
        FLAG_RECREATE=""
    fi

    if [[ "${_AS_DAEMON}" == "true" ]]
    then
        FLAG_DAEMON="-d"
    else
        FLAG_DAEMON=""
    fi

    _cmd="yes | ${WM_CFG_SUDO} docker-compose -f ${_COMPOSE_PATH} up ${FLAG_DAEMON} ${FLAG_RECREATE} --remove-orphans || true"
    web_notify "starting composition: ${_cmd}"
    eval "${_cmd}"
}



# docker_daemon_configuration management
#
# cleans up dangling images
function docker_daemon_configuration
{
    if [[ ! -z "${WM_DOCKER_DAEMON_JSON}" ]]
    then
        web_notify "setting docker daemon with ${WM_DOCKER_DAEMON_JSON}"
        wm_config_template_copy docker_daemon "${WM_CFG_SESSION_STORAGE_PATH}/docker_daemon.tmp"
        ${WM_CFG_SUDO} cp "${WM_CFG_SESSION_STORAGE_PATH}/docker_daemon.tmp" /etc/docker/daemon.json
        ${WM_CFG_SUDO} chown root:root /etc/docker/daemon.json
        ${WM_CFG_SUDO} systemctl restart docker.service
    fi
}



# docker_fetch_settings
#
# retrieves settings from the server
function docker_fetch_settings
{
    if [[ ! -z "${WM_CFG_UPDATE_PATH}" && ! -z "${WM_CFG_UPDATER_IMAGE}" ]]
    then
        wm_config_template_copy "docker-compose.settings" "${WM_CFG_UPDATE_PATH}/docker-compose.yml"
        docker_redeploy "${WM_CFG_UPDATE_PATH}/docker-compose.yml" "false" "true"
        ${WM_CFG_SUDO} systemctl daemon-reload
        ${WM_CFG_SUDO} udevadm trigger
    fi
}


# docker_terminate_services
#
# permanent shutdown of a service
function docker_terminate_services
{
    local _NAME_FILTER
    local _TARGET_CONTAINER
    local _WM_RUNNING_CONTAINERS

    _NAME_FILTER=${1}

    # Necessary to allow successful completion on Raspbian buster
    set +e
    web_notify "terminating services matching: ${_NAME_FILTER}"

    #shellcheck disable=SC2086
    _WM_RUNNING_CONTAINERS=$(${WM_CFG_SUDO} docker ps --filter name=${_NAME_FILTER} -qa)
    set -e

    for _TARGET_CONTAINER in "${_WM_RUNNING_CONTAINERS[@]}"
    do
        web_notify "removing ${_TARGET_CONTAINER}"
        if [[ "${_TARGET_CONTAINER}" ]]
        then
            ${WM_CFG_SUDO} docker rm -f "${_TARGET_CONTAINER}" || true
        else
            web_notify "nothing to cleanup"
        fi
    done

}


# _lookup_devices
#  Iterates local devices
function docker_generate_device_service()
{
    local _TEMPLATE_NAME
    local _COMPOSE_PATH

    local _SINK_ENUMERATION_PATTERN
    local _SINK_ENUMERATION_IGNORE

    local _DEVICE
    local _DEVICE_ID
    local _BLACKLISTED

    _TEMPLATE_NAME=${1:-"lxgw-sink"}
    _COMPOSE_PATH=${2}

    _SINK_ENUMERATION_PATTERN=($(echo "${WM_GW_SINK_PORT_RULE}" | tr " " "\\n"))
    _DEVICE_ID=-1
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

        _DEVICE_ID=$((_DEVICE_ID+1))

        # apply filter based on input
        # shellcheck disable=SC2034
        WM_GW_SINK_UART_PORT_SERVICE_NAME="${_DEVICE/\/dev\//}"
        WM_GW_SINK_UART_PORT=${_DEVICE}
        WM_SINK_UART_BITRATE="${WM_GW_SINK_BITRATE_CONFIGURATION["${_DEVICE_ID}"]}"
        WM_GW_SINK_ID=${_DEVICE_ID}

        web_notify "Configuring ${_DEVICE} (bitrate=${WM_SINK_UART_BITRATE}, id=${WM_GW_SINK_ID})"
        wm_config_template_copy "${_TEMPLATE_NAME}" "${_COMPOSE_PATH}" ">>"

    done
}


# docker_gateway_hook_pre_loop
#
# Hook that is called before launching the gateway services
#
# This hook should perform any cleanup, such as ensuring the
# that the sink is not acquired multiple times.
#
function docker_gateway_hook_pre_loop
{
    export WM_GW_SINK_BITRATE_CONFIGURATION

    web_notify "${WM_GW_STATE} -> ${WM_CFG_GATEWAY_PATH}"

    # ensure no gateway service is running
    if [[ "${WM_GW_CLEANUP}" == "true" ]]
    then
        docker_terminate_services "wm-gw*"
    fi

    # create default bitrate array
    if [[ -z "${WM_GW_SINK_BITRATE_CONFIGURATION}" ]]
    then
        _SINK_BITRATE=()
        for _ in $(seq 0 1 20)
        do
            _SINK_BITRATE+=( "125000" )
        done
    else
        _SINK_BITRATE=($(echo "${WM_GW_SINK_BITRATE_CONFIGURATION}" | tr " " "\\n"))
    fi

    WM_GW_SINK_BITRATE_CONFIGURATION="${_SINK_BITRATE}"

}

# docker_gateway_hook_loop
#
# Hook that is called in order to launch the gateway services.
#
function docker_gateway_hook_loop
{
    export WM_SINK_UART_BITRATE

    # main loop
    if [[ "${WM_GW_STATE}" == "start" ]]
    then
        # forces an update of the symlinks
        ${WM_CFG_SUDO} udevadm trigger || true

        date > "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session"
        mkdir -p "${WM_CFG_GATEWAY_PATH}"
        mkdir -p "${WM_GW_SERVICES_USER_PATH}"

        if [[ "${WM_CFG_GATEWAY_PATH}" == "lxgw" ]] && [[ ! -z "${WM_GW_IMAGE}" ]]
        then
            local _DOCKER_COMPOSE_PATH

            _DOCKER_COMPOSE_PATH="${WM_CFG_GATEWAY_PATH}/docker-compose.yml"
            WM_SINK_UART_BITRATE="${WM_GW_SINK_BITRATE_CONFIGURATION["${WM_GW_SINK_ID}"]}"

            wm_config_template_copy "docker-compose.${WM_CFG_GATEWAY_PATH}" "${_DOCKER_COMPOSE_PATH}"

            web_notify "\\n\\t*SINK* |  id: ${WM_GW_SINK_ID}, port: ${WM_GW_SINK_UART_PORT}, bitrate: ${WM_SINK_UART_BITRATE}
                        \\n\\t*GW* | gw_id: ${WM_GW_ID}, gw_model: ${WM_GW_MODEL}, gw_version: ${WM_GW_VERSION}
                        \\n\\t*MQTT* | broker: ${WM_SERVICES_MQTT_HOSTNAME}"

            # multi sink support
            if [[ "${WM_GW_SINK_ENUMERATION}" == "true" ]]
            then
                wm_config_template_copy docker-compose.lxgw-transport "${_DOCKER_COMPOSE_PATH}"
                docker_generate_device_service docker-compose.lxgw-sink "${_DOCKER_COMPOSE_PATH}"
            fi

            docker_redeploy "${_DOCKER_COMPOSE_PATH}"
        fi
    fi

    if [[ "${WM_GW_STATE}" == "stop" ]]
    then
        echo "stopping gateway ${WM_CFG_GATEWAY_PATH}"
        docker_stop "${WM_CFG_GATEWAY_PATH}"
    fi
}

# docker_gateway_hook_post_loop
#
# Hook that is called after the gateway services are up
#
function docker_gateway_hook_post_loop
{

    docker_service_status
    docker_service_logs

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        docker_cleanup "false"
    fi

    deactivate || true
}



function docker_gateway
{
    docker_gateway_hook_pre_loop
    docker_gateway_hook_loop
    docker_gateway_hook_post_loop
}
