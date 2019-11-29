#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd
#
# functions to interact with web services

WM_CFG_WEBHOOK_POST_URL=${WM_CFG_WEBHOOK_POST_URL:-}

function web_notify
{
    local _ESCAPED_MSG
    local _MESSAGE

    _ESCAPED_MSG=$(echo ${1}|tr -d '"')
    _MESSAGE=$(printf  "*$(hostname)@$(date --iso-8601=seconds)*: %s" "${_ESCAPED_MSG}" )

    echo "${_MESSAGE}"

    if [[ ! -z "${WM_CFG_WEBHOOK_POST_URL}" ]]
    then
        curl -s -X POST \
             -H 'Content-type: application/json' \
             --data "{\"text\": \"${_MESSAGE}\"}" \
             "${WM_CFG_WEBHOOK_POST_URL}"  > /dev/null || true
    fi
}

