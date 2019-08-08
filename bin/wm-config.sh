#!/usr/bin/env bash
# Wirepas Oy - usage means acceptance of the license shared separately
#
# Wirepas Host Configurator - wm-config - by Wirepas Oy
#
# The wm-config attempts to load custom settings from a predefined location.
# Settings read from the given location override any default settings
# read from ~/wirepas/defaults/defaults.env
#
#
# Note:
#   Path variables to *not* contain a trailing slash (/)
#
#
# Argument precedence, from higher to lower precedence:
#
# * Command line paramenters
# * Custom environment file
# * Session environment
# * Default environment file in ~/wirepas/defaults
#

set -o nounset
set -o errexit
set -o errtrace

export PATH=$PATH:/home/${USER}/.local/bin

# _import_modules
#
# fetch fucntions from the modules folder
function _import_modules
{
    for CFILE in $(ls ${WM_SERVICE_HOME}/modules/*.sh)
    do
        echo "importing module ${CFILE}"
        chmod +x ${CFILE} || true
        source ${CFILE} || true
    done

    trap 'wmconfig_error "${BASH_SOURCE}:${LINENO} (rc: ${?})"' ERR
    trap 'wmconfig_finish "${BASH_SOURCE}"' EXIT
}

function _get_platform()
{

    _DEVICE_TREE_MODEL="/proc/device-tree/model"

    export HOST_ARCHITECTURE
    export HOST_IS_RPI
    export HOST_MODEL

    HOST_ARCHITECTURE=$(uname -m)
    HOST_IS_RPI="false"
    HOST_MODEL="unknown"

    if [[ -f "${_DEVICE_TREE_MODEL}" ]]
    then
        HOST_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    fi

    if [[ "${HOST_MODEL}" == *"Raspberry"* ]]
    then
        HOST_IS_RPI="true"
    fi
}



function wmconfig_defaults
{
    WM_CFG_VERSION="#FILLVERSION"
    _get_platform

    DEFAULT_IFS="${IFS}"
    SAFER_IFS=$'\n\t'
    IFS="${SAFER_IFS}"

    _ME=$(basename "${0}")

    if [[ "${HOST_IS_RPI}" == "true" ]]

    then
        WM_CFG_INSTALL_PATH=${WM_CFG_INSTALL_PATH:-/usr/local/bin/wm-config}
        WM_SERVICE_HOME=${WM_SERVICE_HOME:-"${HOME}/wirepas/wm-config"}
        WM_ENTRYPOINT_SETTINGS=${WM_ENTRYPOINT_SETTINGS:-"/boot/wirepas"}
        WM_ENVIRONMENT_CUSTOM=${WM_ENVIRONMENT_CUSTOM:-"${WM_ENTRYPOINT_SETTINGS}/custom.env"}
        WM_ENVIRONMENT_DEFAULT=${WM_ENVIRONMENT_DEFAULT:-"${WM_SERVICE_HOME}/environment/default.env"}
    else
        WM_CFG_INSTALL_PATH=${WM_CFG_INSTALL_PATH:-${HOME}/.local/bin/wm-config}
        WM_SERVICE_HOME=${WM_SERVICE_HOME:-"${HOME}/wirepas/wm-config"}
        WM_ENTRYPOINT_SETTINGS=${WM_ENTRYPOINT_SETTINGS:-"${WM_SERVICE_HOME}"}
        WM_ENVIRONMENT_CUSTOM=${WM_ENVIRONMENT_CUSTOM:-"${WM_ENTRYPOINT_SETTINGS}/environment/custom.env"}
        WM_ENVIRONMENT_DEFAULT=${WM_ENVIRONMENT_DEFAULT:-"${WM_SERVICE_HOME}/environment/default.env"}
    fi

    WM_CFG_STARTUP_DELAY=${WM_CFG_STARTUP_DELAY:-"0"}
    WM_SLACK_WEBHOOK=${WM_SLACK_WEBHOOK:-""}
    WM_MSTEAMS_WEBHOOK=${WM_MSTEAMS_WEBHOOK:-""}
    WM_DOCKER_FORCE_RECREATE=${WM_DOCKER_FORCE_RECREATE:-""}

    WM_CFG_PERIODIC_WORK_PATH=${WM_CFG_PERIODIC_WORK_PATH:-"${WM_SERVICE_HOME}/periodic_work"}
    WM_CFG_HOST_PATH=${WM_CFG_HOST_PATH:-"${WM_SERVICE_HOME}/host"}
    WM_GW_SETTINGS_PATH=${WM_GW_SETTINGS_PATH:-"${WM_SERVICE_HOME}/settings"}
    WM_CFG_TEMPLATE_PATH=${WM_CFG_TEMPLATE_PATH:-"${WM_SERVICE_HOME}/templates"}
    WM_CFG_ARCHIVES_PATH=${WM_CFG_ARCHIVES_PATH:-"${WM_SERVICE_HOME}/archives"}
    WM_CFG_DEPENDENCIES_PATH=${WM_CFG_DEPENDENCIES_PATH:-"${WM_SERVICE_HOME}/dependencies"}

    WM_CONFIG_MULTI_SINK=${WM_CONFIG_MULTI_SINK:-"true"}

    mkdir -p ${WM_GW_SETTINGS_PATH}
    mkdir -p ${WM_CFG_PERIODIC_WORK_PATH}
    mkdir -p ${WM_CFG_HOST_PATH}
    mkdir -p ${WM_CFG_TEMPLATE_PATH}
    mkdir -p ${WM_CFG_ARCHIVES_PATH}
    mkdir -p ${WM_CFG_DEPENDENCIES_PATH}
}


wmconfig_help() {
  cat <<HEREDOC
Wirepas gateway configurator (${WM_CFG_VERSION})

Usage:
  ${_ME} [<arguments>]
  ${_ME} -h | --help
  ${_ME} --start

Options:
  -h --help             Show this screen
  --list                Lists environment and exits

  --state               Move services to start/stop state (default: ${WM_GATEWAY_STATE})
  --update              Forces an update of the base script (default: ${WM_CFG_UPDATE})
  --pull-settings       Pulls a settings container (default: ${WM_CFG_PULL_SETTINGS})

  --force-recreate      Forces running containers to be recreated (default: ${WM_DOCKER_FORCE_RECREATE})
  --force-clean         Force removes any running container (default: ${WM_DOCKER_CLEANUP})

  --disable-updater     Stops and disables the systemd periodic job - ${WM_CFG_SYSTEMD_UPDATER}
  --enable-updater      Enables and starts the systemd periodic job - ${WM_CFG_SYSTEMD_UPDATER}

  --debug               Sets the interpreter to debug mode

HEREDOC
}

#wmconfig_parse
#
# parses the input arguments
function wmconfig_parse
{
    # Gather commands
    while (( "${#}" ))
    do
        case "${1}" in
            --list)
            WM_GATEWAY_STATE=list
            env | grep WM_
            env | grep WM_ > ${WM_SERVICE_HOME}/.wirepas_session
            docker ps -a >> ${WM_SERVICE_HOME}/.wirepas_session
            exit
            ;;

            --state)
            WM_GATEWAY_STATE="$2"
            shift
            shift
            ;;

            --update)
            WM_CFG_UPDATE=true
            shift
            ;;

            --pull-settings)
            WM_CFG_PULL_SETTINGS=true
            shift
            ;;

            --force-recreate)
            WM_DOCKER_FORCE_RECREATE=true
            shift
            ;;
            --force-clean)
            WM_DOCKER_CLEANUP=true
            shift
            ;;

            --disable-updater)
            WM_CFG_SYSTEMD_UPDATER_DISABLE=true
            shift
            ;;

            --disable-sink-discovery)
            WM_CONFIG_MULTI_SINK=false
            shift
            ;;

            --enable-updater)
            WM_CFG_SYSTEMD_UPDATER_ENABLE=true
            shift
            ;;

            --debug)
            set -x
            env |grep WM_ > ~/env.log
            shift
            ;;

            --help)
            wmconfig_help
            exit 1
            ;;

            *) # unsupported flags
            echo "unknown option: ${1}"
            wmconfig_help
            exit 1
            ;;
        esac
    done
}


# _error
#
# prints out errors to the boot sector
function wmconfig_error
{
    TIME_NOW=$(date)
    echo "${TIME_NOW} : Aborting due to errexit on ${@}" > ${WM_SERVICE_HOME}/error.log
    web_notify $(cat "${WM_SERVICE_HOME}/error.log")

    if [[ "${HOST_IS_RPI}" == "true" ]]

    then
        sudo rm -f ${WM_ENTRYPOINT_SETTINGS}/error.log || true

        echo "==== journalctl ====" >> ${WM_SERVICE_HOME}/error.log
        journalctl -u ${WM_CFG_SYSTEMD_UPDATER} >> ${WM_SERVICE_HOME}/error.log

        env|grep WM >> ${WM_SERVICE_HOME}/env.log
        hostname -I >> ${WM_SERVICE_HOME}/env.log

        sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/*.log ${WM_ENTRYPOINT_SETTINGS}/

        sudo rm -f ${WM_SERVICE_HOME}/*.log || true
    fi
}

# _finish
#
# end of the script
function wmconfig_finish
{
    if [[ "${HOST_IS_RPI}" == "true" ]]

    then

        web_notify "Work completed - writing session info to ${WM_ENTRYPOINT_SETTINGS}"

        date > ${WM_SERVICE_HOME}/env.log

        hostname -I >> ${WM_SERVICE_HOME}/env.log
        env|grep WM >> ${WM_SERVICE_HOME}/env.log

        journalctl -u ${WM_CFG_SYSTEMD_UPDATER} > ${WM_SERVICE_HOME}/journal.log

        sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/env.log ${WM_ENTRYPOINT_SETTINGS}/env.log
        sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/journal.log ${WM_ENTRYPOINT_SETTINGS}/journal.log

        if [[ -f ${WM_SERVICE_HOME}/.wirepas_session ]]
        then
            sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/.wirepas_session  ${WM_ENTRYPOINT_SETTINGS}/session.log || true
        fi

        rm -f  ${WM_SERVICE_HOME}/*.log || true

    else
        web_notify "Work completed"
    fi
}



# main execution loop
function _main
{

    # parameter evaluation
    wirepas_load_settings
    wmconfig_parse "$@"

    web_notify "delaying startup for ${WM_CFG_STARTUP_DELAY}"
    sleep ${WM_CFG_STARTUP_DELAY}


    web_notify ":wave:"
    web_notify "wirepas-config build - ${WM_CFG_VERSION}"
    web_notify "Starting work from $(hostname -I)"

    wirepas_session_cleanup

    if [[ "${HOST_IS_RPI}" == "true" ]]

    then
        host_sync_clock
        host_systemd_management
        host_set_keyboard_layout
        host_blacklist_ipv6
        host_upgrade
    fi

    host_install_dependencies
    host_set_aws_credentials

    if [[ "${HOST_IS_RPI}" == "true" ]]

    then
        host_tty_pseudo_names
        host_ssh_network_login
        host_expand_filesystem
        host_setup_user ${WM_HOST_USER_NAME} ${WM_HOST_USER_PASSWORD} ${WM_HOST_USER_PPKI}
        host_setup_hostname
        host_setup_wifi
        wirepas_service_tunnel
        docker_cleanup
    else
        echo "user, hostname and service tunnel only available on RPi"
    fi

    wirepas_dbus_policies
    wirepas_wmconfig_update
    wirepas_gateway "$@"

    if [[ "${HOST_IS_RPI}" == "true" ]]

    then
        docker_cleanup "false"
    fi

    exit "${?}"
}

# Call `_main` after everything has been defined.
wmconfig_defaults
_import_modules
_main "$@"
