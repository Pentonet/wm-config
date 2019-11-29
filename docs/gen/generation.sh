#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

export USER
export HOME
export WM_GW_ID

# Provides a quick list of default keys
function list_default_keys
{
    set -o allexport
    source ./environment/default.env
    set +o allexport

    for key in $(env | grep WM_)
    do
        echo "$key" | awk -F"=" '{print "##"$1 " |  (##" $1 "_DEFAULT)" ;}'
    done
}

# The single quotation is intentionally used to avoid expansion
function _ignored_values
{
    export USER
    export HOME
    export WM_GW_ID

    USER='${USER}'
    HOME='${HOME}'
    WM_GW_ID='`hostname`'
}

function replace_default
{
    for _entry in $(env | grep WM_ )
    do
        _key=$(echo "${_entry}" | awk '{split($0,a,"="); print a[1]}')
        _value=$(echo "${_entry}" | awk '{split($0,a,"="); print a[2]}')

        if [[ "${_key}" != "WM_"* ]]
        then
            continue
        fi

        if [[ -z "${_value}" ]]
        then
            _value="unset"
        fi

        echo "Replacing ##${_key}_DEFAULT -> *default=${_value}*"
        sed -i "s@##${_key}_DEFAULT@*default=${_value}*@" "${PARAM_TABLE}"
    done
}


function replace_key
{
    for _entry in $(env | grep WM_ )
    do
        _key=$(echo ${_entry} | awk '{split($0,a,"="); print a[1]}')
        _value=$(echo ${_entry} | awk '{split($0,a,"="); print a[2]}')

        if [[ ${_key} != "WM_"* ]]
        then
            continue
        fi

        echo "Replacing ##${_key} -> **${_key}**"
        sed -i "s@##${_key}@**${_key}**@" "${PARAM_TABLE}"

    done
}


function update_target
{
    PARAM_TABLE=${1}
    TARGET=${2}

    _ignored_values

    set -o allexport
    source environment/default.env
    set +o allexport

    cp "${PARAM_TABLE}" "${PARAM_TABLE}.tmp"

    replace_default
    replace_key

    rm -f "${PARAM_TABLE}.gen"
    cp "${PARAM_TABLE}" "${PARAM_TABLE}.gen"
    cp "${PARAM_TABLE}.tmp" "${PARAM_TABLE}"
    rm "${PARAM_TABLE}.tmp"

    sed -i -ne "/<!-- auto_start -->/ {p; r ${PARAM_TABLE}.gen" -e ":a; n; /<!-- auto_end -->/ {p; b}; ba}; p" "${TARGET}"
}

