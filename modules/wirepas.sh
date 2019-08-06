#!/usr/bin/env bash
# Wirepas Oy
#
# functions to interact with wirepas components


# wirepas_session_cleanup
#
# cleanup the logging files
function wirepas_session_cleanup
{
    sudo rm -f ${WM_ENTRYPOINT_SETTINGS}*.log || true
    sudo rm -f ${WM_SERVICE_HOME}/*.log || true
    sudo rm -f ${WM_SERVICE_HOME}/*.tmp || true
    sudo rm -f ${WM_SERVICE_HOME}/*.load || true
}

# wirepas_remove_entry
#
# sets the input argument to false
function wirepas_remove_entry
{
    ENTRY=${1}
    echo "removing ${ENTRY} from env files"
    sudo sed -i "/${ENTRY}/d" ${WM_ENVIRONMENT_CUSTOM}

    # force it to false in custom
    cp ${WM_ENVIRONMENT_CUSTOM} ${HOME}/.custom.tmp

    sudo echo "${ENTRY}=false" >> ${HOME}/.custom.tmp
    sudo cp --no-preserve=mode,ownership ${HOME}/.custom.tmp ${WM_ENVIRONMENT_CUSTOM}

    rm ${HOME}/.custom.tmp
}


# wirepas_load_settings
#
# Sources the default and custom file to retrieve the parameter values
function wirepas_load_settings
{
    # load settings from environment files
    set -o allexport

    TEMP_FILE=${WM_SERVICE_HOME}/load.tmp

    if [[ -f ${WM_ENVIRONMENT_CUSTOM} ]]
    then
        web_notify "loading ${WM_ENVIRONMENT_CUSTOM}"

        sudo cp ${WM_ENVIRONMENT_CUSTOM} ${TEMP_FILE}
        host_rm_win_linefeed ${TEMP_FILE} ${TEMP_FILE}.load

        source ${TEMP_FILE}.load

        sudo rm ${TEMP_FILE}
        sudo rm ${TEMP_FILE}.load
    else
        web_notify "could not find ${WM_ENVIRONMENT_CUSTOM}"
        sudo touch "${WM_ENVIRONMENT_CUSTOM}"
    fi

    if [[ -f ${WM_ENVIRONMENT_DEFAULT} ]]
    then
        web_notify "loading ${WM_ENVIRONMENT_DEFAULT}"

        sudo cp ${WM_ENVIRONMENT_DEFAULT} ${TEMP_FILE}
        host_rm_win_linefeed ${TEMP_FILE} ${TEMP_FILE}.load

        source ${WM_ENVIRONMENT_DEFAULT}

        sudo rm ${TEMP_FILE}
        sudo rm ${TEMP_FILE}.load
    else
        web_notify "could not find ${WM_ENVIRONMENT_DEFAULT}"
        exit 1
    fi
    set +o allexport
}



# wirepas_wmconfig_update
#
# updates itself

function wirepas_wmconfig_update
{

    if [[ "${WM_CFG_PULL_SETTINGS}" == "true" ]]
    then
        wirepas_fetch_settings
    else
        web_notify "skipping settings pull"
    fi

    #change to WM_CFG_UPDATE
    if [[ "${WM_CFG_UPDATE}" == "true" ]]
    then
        web_notify "I am updating the base program and scheduling a job restart"

        sudo cp --no-preserve=mode,ownership \
            ${WM_SERVICE_HOME}/bin/wm-config.sh ${WM_CFG_INSTALL_PATH}
        sudo chmod +x ${WM_CFG_INSTALL_PATH}
        sudo chown root:root ${WM_CFG_INSTALL_PATH}

        wirepas_remove_entry "WM_CFG_UPDATE"

        if [[ "${HOST_IS_RPI}" == "true" ]]

        then
            host_reboot 0
            exit 0
        fi
    else
        web_notify "skipping wmconfig update"
    fi
}

# wirepas_template_copy
#
# copies and fills in the template
function wirepas_template_copy
{
    # input name is basename
    TEMPLATE_NAME=${1:-"defaults"}
    OUTPUT_PATH=${2:-"template.output"}
    MULTI=${3:-""}

    # if set, changes the output filename
    mkdir -p "${WM_CFG_TEMPLATE_PATH}"

    if [[ -z "${MULTI}" ]]
    then
        TEMPLATE=${WM_CFG_TEMPLATE_PATH}/${TEMPLATE_NAME}.template
        web_notify "generating ${OUTPUT_PATH} based on ${TEMPLATE}"
        rm -f ${OUTPUT_PATH} ${OUTPUT_PATH}.tmp
        ( echo "cat <<EOF >${OUTPUT_PATH}";
          cat ${TEMPLATE};
          echo "EOF";
        ) > ${OUTPUT_PATH}.tmp
        . ${OUTPUT_PATH}.tmp
        rm ${OUTPUT_PATH}.tmp
    else
        # Create multiple templates from master template
        # Third argument format "string_in_template=start_index-end_index"
        ARRAY=(${MULTI//[=-]/ })
        STRING_IN_TEMPLATE=${ARRAY[0]}
        START_INDEX=${ARRAY[1]}
        END_INDEX=${ARRAY[2]}
        MASTER_TEMPLATE=${WM_CFG_TEMPLATE_PATH}/${TEMPLATE_NAME}.template
        for INDEX in {${START_INDEX}..${END_INDEX}}
        do
            TEMPLATE=${WM_CFG_TEMPLATE_PATH}/${TEMPLATE_NAME}_${INDEX}.template
            sed "s/${STRING_IN_TEMPLATE}/${INDEX}/g" ${MASTER_TEMPLATE} >${TEMPLATE}
            web_notify "generating ${OUTPUT_PATH} based on ${TEMPLATE}"
            rm -f ${OUTPUT_PATH} ${OUTPUT_PATH}.tmp
            ( echo "cat <<EOF >${OUTPUT_PATH}";
              cat ${TEMPLATE};
              echo "EOF";
            ) > ${OUTPUT_PATH}.tmp
            . ${OUTPUT_PATH}.tmp
            rm ${OUTPUT_PATH}.tmp
        done
    fi
}



# wirepas_disable_key
#
# sets the input argument to false
function wirepas_disable_key
{
    ENTRY=${1}
    echo "removing ${ENTRY} from env files"
    sudo sed -i "/${ENTRY}/d" ${WM_ENVIRONMENT_CUSTOM}

    # force it to false in custom
    cp ${WM_ENVIRONMENT_CUSTOM} ${WM_SERVICE_HOME}/.custom.tmp

    sudo echo "${ENTRY}=false" >> ${WM_SERVICE_HOME}/.custom.tmp
    sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/.custom.tmp ${WM_ENVIRONMENT_CUSTOM}

    rm ${WM_SERVICE_HOME}/.custom.tmp
}


# wirepas_terminate_services
#
# permanent shutdown of a service
function wirepas_terminate_services
{
    NAME_FILTER=${1}

    # Necessary to allow successful completion on Raspbian buster
    set +e
    web_notify "terminating services matching: ${NAME_FILTER}"
    WM_RUNNING_CONTAINERS=$(docker ps --filter name=${NAME_FILTER} -qa)
    set -e

    for REMOVE_CONTAINER in ${WM_RUNNING_CONTAINERS[@]}
    do
        echo ${REMOVE_CONTAINER}
        if [[ "${REMOVE_CONTAINER}" ]]
        then
            docker rm -f ${REMOVE_CONTAINER} || true
        else
            echo "nothing to cleanup"
        fi
    done

}


# wirepas_fetch_settings
#
# retrieves settings from the server
function wirepas_fetch_settings
{
    if [[ ! -z "${WM_GW_SETTINGS_PATH}" && ! -z "${WM_CFG_SETTINGS_IMAGE}" ]]
    then
        wirepas_template_copy "docker-compose.settings" ${WM_GW_SETTINGS_PATH}/docker-compose.yml
        docker_redeploy "${WM_GW_SETTINGS_PATH}/docker-compose.yml" "false" "true"
        sudo systemctl daemon-reload
        sudo udevadm trigger
    fi
}


# wirepas_service_tunnel
#
# checks if a support key is present and establishes a tunnel to the target server
function wirepas_service_tunnel
{
    WM_PHONE_TEMPLATE=${WM_PHONE_TEMPLATE:-"wirepas-phone"}

    if [[ -f "${WM_SUPPORT_HOST_KEY}" ]]
    then
        web_notify "starting phone support to ${WM_SUPPORT_HOST_USER}@${WM_SUPPORT_HOST_NAME}:${WM_SUPPORT_HOST_PORT} (key: ${WM_SUPPORT_HOST_KEY_PATH})"

        sudo cp ${WM_SUPPORT_HOST_KEY} ${WM_SUPPORT_HOST_KEY_PATH}
        sudo chmod 400 ${WM_SUPPORT_HOST_KEY_PATH}
        sudo chown $(id -u):$(id -g) ${WM_SUPPORT_HOST_KEY_PATH}

        wirepas_template_copy ${WM_PHONE_TEMPLATE} ${WM_SERVICE_HOME}/wirepas-phone.service
        sudo cp --no-preserve=mode,ownership ${WM_SERVICE_HOME}/wirepas-phone.service /etc/systemd/system/wirepas-phone.service
        rm ${WM_SERVICE_HOME}/wirepas-phone.service

        sudo systemctl daemon-reload
        sudo systemctl start wirepas-phone.service
    else

        web_notify "ensuring tunnel is down"
        sudo systemctl stop wirepas-phone.service || true
        sudo rm -f /etc/systemd/system/wirepas-phone.service || true

    fi
}


function wirepas_dbus_policies
{
    if [[ ! -f /etc/dbus-1/system.d/${WM_LXGW_DBUS_CONF} ]]
    then
        _target="/etc/dbus-1/system.d/${WM_LXGW_DBUS_CONF}"
        _target_tmp="${WM_SERVICE_HOME}/${WM_LXGW_DBUS_CONF}.tmp"

        wirepas_template_copy ${WM_LXGW_DBUS_CONF} ${_target_tmp}
        sudo cp --no-preserve=mode,ownership ${_target_tmp} ${_target}
        rm ${_target_tmp}

        if [[ "${HOST_IS_RPI}" == "true" ]]

        then
            host_reboot 0
            exit 0
        else
            echo "added new dbus policy a reboot is advisable"
        fi
    fi
}


# wirepas_gateway
#
# starts and switches between WM services
function wirepas_gateway
{
    web_notify "${WM_GATEWAY_STATE} -> ${WM_GATEWAY}"

    # ensure nothing is running
    if [[ "${WM_GATEWAY_CLEANUP}" == "true" ]]
    then
        wirepas_terminate_services "wm-*"
    fi

    # main loop
    if [[ "${WM_GATEWAY_STATE}" == "start" ]]
    then

        # forces an update of the symlinks
        sudo udevadm trigger || true

        date > ${WM_SERVICE_HOME}/.wirepas_session
        for GW in ${WM_GATEWAY[@]}
        do
            mkdir -p ${WM_SERVICE_HOME}/${GW}

            _docker_compose_path="${WM_SERVICE_HOME}/${GW}/docker-compose.yml"

            wirepas_template_copy docker-compose.${GW} ${_docker_compose_path}

            if [[ "${GW}" == "pygw" ]] && [[ ! -z "${WM_PYGW_IMAGE}" ]]
            then
                WM_SERVICES_GATEWAY_MODEL=${WM_SERVICES_GATEWAY_MODEL:-"wirepas-evk"}
                WM_SERVICES_GATEWAY_VERSION=${WM_SERVICES_GATEWAY_VERSION:-"${WM_PYGW_IMAGE}:${WM_PYGW_VERSION}"}

                web_notify "gateway software build: ${WM_PYGW_IMAGE}:${WM_PYGW_VERSION}"

                # stop others
                wirepas_terminate_services "wm-lx*"
                wirepas_terminate_services "wm-db*"
                wirepas_terminate_services "wm-sd*"

                # create settings
                wirepas_template_copy ${GW} ${WM_SERVICE_HOME}/${GW}/inits/${GW}.ini

                docker_redeploy ${_docker_compose_path}
            fi


            if [[ "${GW}" == "lxgw" ]] && [[ ! -z "${WM_LXGW_IMAGE}" ]]
            then
                WM_SERVICES_GATEWAY_MODEL=${WM_SERVICES_GATEWAY_MODEL:-"wirepas-evk"}
                WM_SERVICES_GATEWAY_VERSION=${WM_SERVICES_GATEWAY_VERSION:-"${WM_LXGW_IMAGE}:${WM_LXGW_VERSION}"}

                web_notify "gateway software build: ${WM_LXGW_IMAGE}:${WM_LXGW_VERSION}"
                web_notify "\n*SINK:* ${WM_SINK_ID}, ${WM_SINK_UART_PORT}, ${WM_SINK_UART_BITRATE}\n*GWID:* ${WM_SERVICES_GATEWAY_ID}\n*MQTT_HOST:* ${WM_SERVICES_HOST}"

                # stop others
                wirepas_terminate_services "wm-py*"
                wirepas_terminate_services "wm-sd*"

                docker_redeploy ${_docker_compose_path}
            fi


            if [[ "${GW}" == "nlgw" ]]
            then
                web_notify "Native Linux Gateway software build"
                ### TODO ###
            fi


            if [[ "${GW}" == "sdgw" ]]
            then
                WM_SDGW_TAR_PATH=${WM_SDGW_TAR_PATH:-"${WM_ENTRYPOINT_SETTINGS}/wm-gateway.tar.gz"}
                WM_SDGW_SCRIPT_PATH=${WM_SDGW_SCRIPT_PATH:-"${WM_ENTRYPOINT_SETTINGS}/run.sh"}

                if [[ -f ${WM_SDGW_TAR_PATH} ]]
                then
                    web_notify "extracting ${WM_SDGW_TAR_PATH} -> ${WM_SERVICE_HOME}/${GW}"
                    tar -xf ${WM_SDGW_TAR_PATH} -C ${WM_SERVICE_HOME}/${GW}
                else
                    web_notify "using files already present in ${WM_SERVICE_HOME}/${GW}"
                fi

                if [[ ! -f "${WM_SDGW_SCRIPT_PATH}" ]]
                then
                    # create settings
                    wirepas_template_copy wm_gateway ${WM_SERVICE_HOME}/${GW}/wm_gateway.env
                    web_notify "\n*SINK:* ${WM_SINK_ID}, ${WM_SINK_UART_PORT}, ${WM_SINK_UART_BITRATE}\n*GWID:* ${WM_SERVICES_GATEWAY_ID}\n*MQTT_HOST:* ${WM_SERVICES_HOST}"

                    # stop others
                    wirepas_terminate_services "wm-py*"
                    wirepas_terminate_services "wm-lx*"

                    docker_redeploy ${_docker_compose_path}
                else
                    STORE_ENV_PATH="${WM_SERVICE_HOME}/.wirepas_session"
                    web_notify "executing custom entrypoint script - path to environment variables ${STORE_ENV_PATH}"
                    env | grep "WM_" > ${STORE_ENV_PATH}
                    cp ${WM_SDGW_SCRIPT_PATH} ${WM_SERVICE_HOME}/${GW}/run.sh
                    chown $(id -u):$(id -g) ${WM_SERVICE_HOME}/${GW}/run.sh
                    chmod +x ${WM_SERVICE_HOME}/${GW}/run.sh
                    exec "${WM_SERVICE_HOME}/${GW}/run.sh"
                fi
            fi

            docker_service_status
        done
    fi

    if [[ "${WM_GATEWAY_STATE}" == "stop" ]]
    then
        for GW in ${WM_GATEWAY[@]}
        do
            echo "stopping gateway ${WM_GATEWAY}"
            cd ${WM_SERVICE_HOME}/${GW}
            docker_stop
        done
        docker ps -a >> ${WM_SERVICE_HOME}/.wirepas_session
    fi
}


