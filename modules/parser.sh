#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd


function wm_config_help
{
    local _ME
    _ME=$(basename "${0}")
    cat <<HEREDOC
Wirepas host configurator - wm-config (${WM_CFG_VERSION})

WM-CONFIG is a bash utility that helps you install system dependencies
and manage the status of wirepas services, such as the gateway's sink and
transport services.

This utility can be called from any location within your user environment.
To run it and show this screen type:

$ wm-config --help

The utility relies on docker and docker-compose to launch and heal
the gateway services. Please refer to the documentation under
wirepas/wm-config for more information.


Providing custom files to the containers:

Containers are isolated from your local system, hence you will have
to mount any folder or file you may need using the docker-compose
files. A default folder will be mounted for the transport and
sink service and is controled by WM_GW_SERVICES_USER_PATH.

Create the folder WM_GW_SERVICES_USER_PATH and drop your
files within it. They will become available within the container
under /etc/lxgw/usr.


Host details discovered by the setup:
    arch                        ${WM_CFG_HOST_ARCH}
    model                       ${WM_CFG_HOST_MODEL}
    is_rpi                      ${WM_CFG_HOST_IS_RPI}

Usage:
  ${_ME} [<Options>]
  ${_ME} -h | --help
  ${_ME}

Options:
  --help                  Show this screen
  --list                     Lists environment and exits

  --state                    Move services to start/stop state (default: ${WM_GW_STATE})
  --status                   Check what is the service status
  --update                   Forces an update of the base script (default: ${WM_CFG_FRAMEWORK_UPDATE})

  --force-recreate           Forces running containers to be recreated (default: ${WM_DOCKER_FORCE_RECREATE})
  --force-clean              Force removes any running container (default: ${WM_DOCKER_CLEANUP})

  --disable-updater          Stops and disables the systemd periodic job (default: ${WM_SYSTEMD_UPDATER})
  --enable-updater           Enables and starts the systemd periodic job (default: ${WM_SYSTEMD_UPDATER})

  --enable-multi-sink        Enables wm-config to lookup all the sinks under /dev/ttyACM* and /dev/ttyUSB* (default: ${WM_GW_SINK_ENUMERATION})

  --debug                    Sets the interpreter to debug mode

HEREDOC
}



# wm_config_parser
#
# parses the input arguments
function wm_config_parser
{
    # Gather commands
    while (( "${#}" ))
    do
        case "${1}" in
            --list)
            export WM_GW_STATE
            WM_GW_STATE=list
            env | grep "WM_"
            env | grep "WM_" > "${WM_CFG_SESSION_STORAGE_PATH}/session.log"
            docker ps -a >> "${WM_CFG_SESSION_STORAGE_PATH}/session.log"
            exit
            ;;

            --status)
            docker_service_status
            docker_service_logs
            exit 0
            ;;

            --state)
            export WM_GW_STATE
            WM_GW_STATE="$2"
            shift
            shift
            ;;

            --update)
            export WM_CFG_FRAMEWORK_UPDATE
            WM_CFG_FRAMEWORK_UPDATE=true
            shift
            ;;

            --force-recreate)
            export WM_DOCKER_FORCE_RECREATE
            WM_DOCKER_FORCE_RECREATE=true
            shift
            ;;

            --force-clean)
            export WM_DOCKER_CLEANUP
            WM_DOCKER_CLEANUP=true
            shift
            ;;

            --disable-updater)
            export WM_SYSTEMD_UPDATER_DISABLE
            WM_SYSTEMD_UPDATER_DISABLE=true
            shift
            ;;

            --disable-sink-discovery)
            export WM_GW_SINK_ENUMERATION
            WM_GW_SINK_ENUMERATION=false
            shift
            ;;

            --enable-updater)
            export WM_SYSTEMD_UPDATER_ENABLE
            WM_SYSTEMD_UPDATER_ENABLE=true
            shift
            ;;

            --enable-multi-sink)
            export WM_GW_SINK_ENUMERATION
            WM_GW_SINK_ENUMERATION=true
            shift
            ;;

            --debug)
            set -x
            env |grep WM_ > "${WM_CFG_SESSION_STORAGE_PATH}/env.log"
            export WM_CFG_FRAMEWORK_DEBUG
            WM_CFG_FRAMEWORK_DEBUG=true
            shift
            ;;

            --help)
            wm_config_help
            exit 1
            ;;

            *) # unsupported flags
            echo "unknown option: ${1}"
            wm_config_help
            exit 1
            ;;
        esac
    done
}

