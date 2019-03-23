#!/usr/bin/env bash
# Wirepas Oy

set -x
set -e


TAR_DIR="."
TAR_NAME="wmconfig.tar.gz"
TAR_OUTPUT_PATH="deliverable"
TAR_EXCLUDE_RULES=".tarignore"


BUILD_VERSION=$(git log -n 1 --oneline --format=%H)
TARGETS=("./bin/wm-config.sh" "./bin/wmconfig-settings-updater.sh")


function _fill_and_pack
{

    _targets=("$@")
    for _target in "${_targets[@]}";
    do
        echo "filling version on: ${_target}"
        _temporary=${_target}.tmp

        cp ${_target} ${_temporary}
        sed -i "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" ${_target}
    done

    tar -zcvf ${TAR_OUTPUT_PATH}/${TAR_NAME} -X ${TAR_EXCLUDE_RULES} -C ${TAR_DIR} .

    for target in "${_targets[@]}"
    do
        echo "reseting: ${target}"
        _target="${target}"
        git checkout -- "${target}"
    done

}


function _main
{
    mkdir -p ${TAR_OUTPUT_PATH}
    rm -f ${TAR_OUTPUT_PATH}/${TAR_NAME}

    _fill_and_pack "${TARGETS[@]}"
}

_main "${@}"

