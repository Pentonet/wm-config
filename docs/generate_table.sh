#!/usr/bin/env bash
# Wirepas Oy


set -o allexport

PARAM_TABLE="docs/readme_table.rst"

source environment/default.env
cp ${PARAM_TABLE} ${PARAM_TABLE}.tmp

function replace_default
{
    for _entry in $(env | grep WM_ )
    do
        _key=$(echo ${_entry} | awk '{split($0,a,"="); print a[1]}')
        _value=$(echo ${_entry} | awk '{split($0,a,"="); print a[2]}')

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

    sed -i -ne "/.. _table_start:/ {p; r ${PARAM_TABLE}.gen" -e ":a; n; /.. _table_end:/ {p; b}; ba}; p" README.rst
}


_main "${@}"


