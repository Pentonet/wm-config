#!/usr/bin/env bash
# Wirepas Oy
#
# functions to interact with web services

function web_notify
{
    escaped_msg=$(echo ${1}|tr -d '"')
    message=$(printf  "*$(hostname)@$(date --iso-8601=seconds)*: %s" ${escaped_msg} )
    echo $message

    if [[ ! -z "${WM_SLACK_WEBHOOK}" ]]
    then
        curl -s -X POST \
             -H 'Content-type: application/json' \
             --data "{\"text\": \"${message}\"}" \
             "${WM_SLACK_WEBHOOK}"  > /dev/null || true
    fi

    if [[ ! -z "${WM_MSTEAMS_WEBHOOK}" ]]
    then
        curl -s -X POST \
             -H 'Content-type: application/json' \
             --data "{\"text\": \"${message}\"}" \
             "${WM_MSTEAMS_WEBHOOK}"  > /dev/null || true
    fi
}

