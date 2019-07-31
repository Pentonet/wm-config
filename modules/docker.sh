#!/usr/bin/env bash
# Wirepas Oy
#
# functions to interact with docker

# docker_add_user
#
# adds user to docker group
function docker_add_user
{
    _username=${1:-"${USER}"}
    if ! groups ${_username} | grep &>/dev/null '\bdocker\b'; then
        web_notify "adding user to docker group"
        sudo usermod -aG docker ${_username} || true
    fi
}

# docker_service_status
#
# waits for a given amount of time and prints container status
function docker_service_status
{
    web_notify "presenting service status in +${WM_DOCKER_STATUS_DELAY}"
    sleep "${WM_DOCKER_STATUS_DELAY}"

    docker ps -a >> ${WM_SERVICE_HOME}/.wirepas_session
    web_notify "$(printf "%s\n" $(docker ps --format '{{.Names}} : {{.Status}} : {{.Image}} | '))"
}


# docker_cleanup management
#
# cleans up dangling images
function docker_cleanup
{
    _wipe_all=${1:-"${WM_DOCKER_CLEANUP}"}

    if [[ "${_wipe_all}" == "true" ]]
    then
        #Necessary to allow successful completion on Raspbian buster see #25
        set +e
        web_notify "removing all containers"
        docker rm -f $(docker ps -aq) || true
        wirepas_remove_entry "WM_DOCKER_CLEANUP"
        set -e
    fi

    # Necessary to allow successful completion on Raspbian buster see #25
    set +e
    web_notify "pruning all _unused_ docker elements"
    docker system prune --all --force || true
    set -e

}


# docker_stop
#
# stop the service execution
function docker_stop
{
    web_notify "stopping services in $(pwd)"
    docker-compose down
}


# docker_login
#
# authenticates with a docker repository
function docker_login
{
    if [[ "${WM_DOCKER_REGISTRY_LOGIN}" == "true" \
        &&  ! -z "${WM_AWS_ACCOUNT_ID}" \
        &&  ! -z "${WM_AWS_REGION}" \
        &&  ! -z "${WM_AWS_SECRET_ACCESS_KEY}" \
        &&  ! -z "${WM_AWS_ACCESS_KEY_ID}" ]]
    then
        WM_AWS_REGION=${WM_AWS_REGION:-"eu-central-1"}

        web_notify "logging in with AWS - ${WM_AWS_ACCOUNT_ID} in ${WM_AWS_REGION}"
        yes | eval $(aws ecr get-login --region ${WM_AWS_REGION} --no-include-email) || true
        if [[ "$?" == 1 ]]
        then
            web_notify "could not login with AWS - please reboot"
        fi
    else
        web_notify "skipping AWS login"
    fi
}


# docker_redeploy
#
# pulls and recreates the services
function docker_redeploy
{
    _compose_path=${1}
    _as_daemon=${2:-"true"}
    WM_DOCKER_FORCE_RECREATE=${3:-"${WM_DOCKER_FORCE_RECREATE}"}

    docker_login

    web_notify "pulling updates to service images"
    yes | docker-compose -f "${_compose_path}" pull --ignore-pull-failures || true

    if [[ "${WM_DOCKER_FORCE_RECREATE}" == "true" ]]
    then
        FLAG_RECREATE="--force-recreate"
    else
        FLAG_RECREATE=""
    fi

    if [[ "${_as_daemon}" == "true" ]]
    then
        FLAG_DAEMON="-d"
    else
        FLAG_DAEMON=""
    fi

    _cmd="yes | docker-compose -f ${_compose_path} up ${FLAG_DAEMON} ${FLAG_RECREATE} --remove-orphans || true"
    web_notify "starting composition: ${_cmd}"
    eval "${_cmd}"
}



# docker_daemon_configuration management
#
# cleans up dangling images
function docker_daemon_configuration
{
    if [[ "${WM_DOCKER_CONFIGURE_DAEMON}" == "true" ]]
    then
        web_notify "setting docker daemon with ${WM_DOCKER_DAEMON_JSON}"
        wirepas_template_copy docker_daemon ${WM_SERVICE_HOME}/docker_daemon.tmp
        sudo cp ${WM_SERVICE_HOME}/docker_daemon.tmp /etc/docker/daemon.json
        sudo chown root:root /etc/docker/daemon.json

        sudo systemctl restart docker.service
    fi
}

