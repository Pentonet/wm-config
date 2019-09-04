#!/usr/bin/env bash
# Wirepas Oy

set -o allexport

PARAM_TABLE="docs/readme_table.md"
README_PATH="README.md"

# The single quatation is intentionally used here, so that reference to
# environment varianble would be included to documentation, rather than
# value from the document generation run.
USER='${USER}'                      # [[ignore]] Expressions don't expand in single quotes, use double quotes for that.
HOME='${HOME}'                      # [[ignore]] Expressions don't expand in single quotes, use double quotes for that.
WM_SERVICES_GATEWAY_ID='`hostname`' # [[ignore]] Expressions don't expand in single quotes, use double quotes for that.

source environment/default.env
cp ${PARAM_TABLE} ${PARAM_TABLE}.tmp

function replace_default
{
    for _entry in $(env | grep WM_ )
    do
        _key=$(echo ${_entry} | awk '{split($0,a,"="); print a[1]}')
        _value=$(echo ${_entry} | awk '{split($0,a,"="); print a[2]}')

        if [[ ${_key} != "WM_"* ]]
        then
            continue
        fi

        if [[ -z "${_value}" ]]
        then
            _value="unset"
        fi

        echo "Replacing ##${_key}_DEFAULT -> *default=${_value}*"
        sed -i "s@##${_key}_DEFAULT\>@*default=${_value}*@" ${PARAM_TABLE}
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
        sed -i "s@##${_key}\>@**${_key}**@" ${PARAM_TABLE}

    done
}


function _main
{
    replace_default
    replace_key

    rm -f ${PARAM_TABLE}.gen
    cp ${PARAM_TABLE} ${PARAM_TABLE}.gen
    cp ${PARAM_TABLE}.tmp ${PARAM_TABLE}
    rm ${PARAM_TABLE}.tmp


    sed -i -ne "/<!-- table_start -->/ {p; r ${PARAM_TABLE}.gen" -e ":a; n; /<!-- table_end -->/ {p; b}; ba}; p" "${README_PATH}"
}


_main "${@}"
