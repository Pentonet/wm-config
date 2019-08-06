#!/usr/bin/env bash
# Wirepas Oy

set -e


BUILD_VERSION=$(git log -n 1 --oneline --format=%h)

TARGETS=("./bin/wm-config.sh" "./bin/wmconfig-settings-updater.sh")
TAR_DIR="."
TAR_NAME="wmconfig.tar.gz"
TAR_OUTPUT_PATH="deliverable"
TAR_EXCLUDE_RULES=".tarignore"


function _check_changes()
{
    if [[ ! -z "$(git status --porcelain)" ]]
    then
        echo "Please commit or stash your changes before packing"
        exit 1
    fi
}


function _fill_and_pack
{

    _targets=("$@")
    for _target in "${_targets[@]}";
    do
        echo "filling version on: ${_target}"
        _temporary=${_target}.tmp

        cp "${_target}" "${_temporary}"
        sed -i "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" "${_target}"
    done

    tar -zcvf "${TAR_OUTPUT_PATH}/${TAR_NAME}" -X "${TAR_EXCLUDE_RULES}" -C "${TAR_DIR}" .

    for target in "${_targets[@]}"
    do
        echo "reseting: ${target}"
        _target="${target}"
        git checkout -- "${target}"
    done
}


function _main
{
    _check_changes

    mkdir -p "${TAR_OUTPUT_PATH}"
    rm -f "${TAR_OUTPUT_PATH}/${TAR_NAME}"

    _fill_and_pack "${TARGETS[@]}"
}

_main "${@}"

