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
        sudo usermod -aG docker "${_USERNAME}" || true
    fi
}


# docker_service_status
#
# waits for a given amount of time and prints container status
function docker_service_status
{
    web_notify "presenting service status in +${WM_DOCKER_STATUS_DELAY}"
    sleep "${WM_DOCKER_STATUS_DELAY}"

    docker ps -a >> "${WM_CFG_INSTALL_PATH}/.wirepas_session"
    #shellcheck disable=SC2046
    web_notify "$(printf "%s\\n" $(docker ps --format '{{.Names}} : {{.Status}} : {{.Image}} '))"
}

# docker_service_logs
#
# waits for a given amount of time and prints container status
function docker_service_logs
{
    local _COMPOSE_PATH
    _COMPOSE_PATH=${1:-"${WM_CFG_GATEWAY_PATH}/docker-compose.yml"}
    docker-compose -f "${_COMPOSE_PATH}" logs -t --tail 20
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



# docker_backwards_compat
#
# Ensures that <1.2.x env parameters are propagated properly
# in later releases (up to when they are deprecated)
#
# If any old setting is available from the environment, it will
# be used, instead of the new names.
#
function docker_backwards_compat_transport_service(){

    export WM_SERVICES_GATEWAY_ID
    export WM_SERVICES_GATEWAY_MODEL
    export WM_SERVICES_GATEWAY_VERSION

    export WM_SERVICES_HOST
    export WM_SERVICES_MQTT_USER
    export WM_SERVICES_ALLOW_UNSECURE
    export WM_SERVICES_CERTIFICATE_CHAIN

    export WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER
    export WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER


    WM_SERVICES_GATEWAY_ID=${WM_SERVICES_GATEWAY_ID:-${WM_GW_ID}}
    WM_SERVICES_GATEWAY_MODEL=${WM_SERVICES_GATEWAY_MODEL:-${WM_GW_MODEL}}
    WM_SERVICES_GATEWAY_VERSION=${WM_SERVICES_GATEWAY_VERSION:-${WM_GW_VERSION}}

    WM_SERVICES_HOST=${WM_SERVICES_HOST:-${WM_SERVICES_MQTT_HOSTNAME}}
    WM_SERVICES_MQTT_USER=${WM_SERVICES_MQTT_USER:-${WM_SERVICES_MQTT_USERNAME}}

    # No change for WM_SERVICES_MQTT_PORT, WM_SERVICES_MQTT_USERNAME,
    # WM_SERVICES_MQTT_PASSWORD, WM_SERVICES_ALLOW_UNSECURE, WM_SERVICES_MQTT_PERSIST_SESSION, WM_SERVICES_CERTIFICATE_CHAIN
    # WM_SERVICES_CERTIFICATE_CHAIN, WM_SERVICES_TLS_CLIENT_CERTIFICATE, WM_SERVICES_TLS_CLIENT_KEY
    # WM_SERVICES_TLS_CERT_REQS, WM_SERVICES_TLS_VERSION, WM_SERVICES_TLS_CIPHERS

    WM_SERVICES_ALLOW_UNSECURE=${WM_SERVICES_ALLOW_UNSECURE:-${WM_SERVICES_MQTT_ALLOW_UNSECURE}}
    WM_SERVICES_CERTIFICATE_CHAIN=${WM_SERVICES_CERTIFICATE_CHAIN:-${WM_SERVICES_MQTT_CERTIFICATE_CHAIN}}

    WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER=${WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER:-${WM_GW_IGNORED_ENDPOINTS_FILTER}}
    WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER=${WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER:-${WM_GW_WHITENED_ENDPOINTS_FILTER}}
}

function docker_backwards_compat_sink_service()
{
    export WM_SINK_UART_PORT
    export WM_SINK_UART_BITRATE
    export WM_SINK_ID

    WM_SINK_UART_PORT=${WM_SINK_UART_PORT:-${WM_GW_SINK_UART_PORT}}
    WM_SINK_UART_BITRATE=${WM_SINK_UART_BITRATE:-${WM_GW_SINK_BITRATE_CONFIGURATION}}
    WM_SINK_ID=${WM_SINK_ID:-${WM_GW_SINK_ID}}
}


# docker_redeploy
#
# pulls and recreates the services
function docker_redeploy
{
    local _compose_path
    local _force_recreate
    local _image_digest_local
    local _image_digest_pull

    _compose_path=${1:-"${WM_CFG_GATEWAY_PATH}/docker-compose.yml"}
    _force_recreate=${WM_DOCKER_FORCE_RECREATE:-}
    _image_digest_local=$(docker image ls "${WM_GW_IMAGE}:${WM_GW_VERSION}" --format "{{.ID}}: {{.Repository}}")

    web_notify "pulling updates to service images: ${_image_digest_local}"
    yes | docker-compose -f "${_compose_path}" pull --ignore-pull-failures || true

    if [[ "${_force_recreate}" == "true" ]]
    then
        _flag_recreate="--force-recreate"
    else
        _flag_recreate=
    fi

    _image_digest_pull=$(docker image ls "${WM_GW_IMAGE}:${WM_GW_VERSION}" --format "{{.ID}}: {{.Repository}}")
    web_notify "starting composition: ${_image_digest_pull}"
    yes | docker-compose -f "${_compose_path}" up -d ${_flag_recreate} --remove-orphans || true
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
        sudo cp "${WM_CFG_SESSION_STORAGE_PATH}/docker_daemon.tmp" /etc/docker/daemon.json
        sudo chown root:root /etc/docker/daemon.json
        sudo systemctl restart docker.service
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
        docker_redeploy "${WM_CFG_UPDATE_PATH}/docker-compose.yml"
        sudo systemctl daemon-reload
        sudo udevadm trigger
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
    _WM_RUNNING_CONTAINERS=$(docker ps --filter name=${_NAME_FILTER} -qa)
    set -e

    for _TARGET_CONTAINER in "${_WM_RUNNING_CONTAINERS[@]}"
    do
        web_notify "removing ${_TARGET_CONTAINER}"
        if [[ "${_TARGET_CONTAINER}" ]]
        then
            docker rm -f "${_TARGET_CONTAINER}" || true
        else
            web_notify "nothing to cleanup"
        fi
    done

}


#  docker_append_service_logging
#  Outputs a transport service with expanded environment variables
function docker_append_service_logging()
{
    local _COMPOSE_PATH
    _COMPOSE_PATH=${1}

    if [[ ! -z "${WM_SERVICES_FLUENTD_HOSTNAME}" && "${WM_SERVICES_FLUENTD_DOCKER_CLI}" == "true" ]]
    then
        wm_config_template_copy docker-compose.lxgw-fluentd-logging "${_COMPOSE_PATH}" ">>"
    else
        wm_config_template_copy docker-compose.lxgw-journald-logging "${_COMPOSE_PATH}" ">>"
    fi

}

#  docker_append_transport_service
#  Outputs a transport service with expanded environment variables
function docker_append_transport_service()
{
    local _TEMPLATE_NAME
    local _COMPOSE_PATH

    _TEMPLATE_NAME=${1:-"docker-compose.lxgw-transport"}
    _COMPOSE_PATH=${2}

    docker_backwards_compat_transport_service
    wm_config_template_copy "${_TEMPLATE_NAME}" "${_COMPOSE_PATH}" ">>"
    docker_append_service_logging "${_COMPOSE_PATH}"
}


#  docker_append_sink_service
#  Generates a sink service based on the discovered devices
function docker_append_sink_service()
{
    local _TEMPLATE_NAME
    local _COMPOSE_PATH

    _TEMPLATE_NAME=${1:-"docker-compose.lxgw-sink"}
    _COMPOSE_PATH=${2}

    _DEVICE_ID=-1
    for _DEVICE in "${WM_GW_SINK_LIST[@]}"
    do
        _DEVICE_ID=$((_DEVICE_ID+1))

        # apply filter based on input
        # shellcheck disable=SC2034
        WM_GW_SINK_UART_PORT_NAME="${_DEVICE/\/dev\//}"
        WM_GW_SINK_UART_PORT=${_DEVICE}
        WM_GW_SINK_UART_BITRATE="${WM_GW_SINK_BITRATE_CONFIGURATION}[${_DEVICE_ID}]"
        WM_GW_SINK_ID=${_DEVICE_ID}

        web_notify "configuring ${_DEVICE} (bitrate=${WM_GW_SINK_UART_BITRATE}, id=${WM_GW_SINK_ID})"
        docker_backwards_compat_sink_service
        wm_config_template_copy "${_TEMPLATE_NAME}" "${_COMPOSE_PATH}" ">>"
        docker_append_service_logging "${_COMPOSE_PATH}"
    done
}


# docker_gateway
#
# Hook that is called in order to launch the gateway services.
#
function docker_gateway
{
    local WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH
    WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH="${WM_CFG_GATEWAY_PATH}/docker-compose.yml"

    # ensure no gateway service is running
    if [[ "${WM_GW_CLEANUP}" == "true" ]]
    then
        docker_terminate_services "wm-gw*"
    fi

    web_notify "setting docker gateway: ${WM_GW_STATE} --> ${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}"

    if [[ "${WM_GW_STATE}" == "start" || "${WM_GW_STATE}" == "up" ]]
    then
        date > "${WM_CFG_SESSION_STORAGE_PATH}/.wirepas_session"
        mkdir -p "${WM_CFG_GATEWAY_PATH}"
        mkdir -p "${WM_GW_SERVICES_USER_PATH}"

        # creates the composition file
        wm_config_template_copy docker-compose.lxgw "${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}" ">"
        docker_append_transport_service docker-compose.lxgw-transport "${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}"
        docker_append_sink_service docker-compose.lxgw-sink "${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}"

        docker_redeploy "${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}"
    fi

    if [[ "${WM_GW_STATE}" == "stop" || "${WM_GW_STATE}" == "down" ]]
    then
        docker_stop "${WM_CFG_DOCKER_GATEWAY_COMPOSE_PATH}"
    fi

    docker_service_status
    docker_service_logs

    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        host_docker_daemon_management "false"
    fi
}


# wm_config_session_main
# Implements the main hook to allow setting up the gateway on top of docker
function wm_config_session_main
{
    docker_gateway
}
