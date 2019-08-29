#!/usr/bin/env bash
# Wirepas Ltd
#
# This build script requires the docker daemon buildx plugin
# Read how to install it from: https://github.com/docker/buildx
#

set -e

MAKE_PUSH=${1:-"false"}
PLATFORM_LIST="linux/amd64,linux/arm64,linux/arm/v7"
DOCKERFILE_PATH="container/Dockerfile"
BUILD_VERSION=$(< setup.sh awk  -F '[=]' '/BUILD_VERSION=\"/{print $NF}'| tr -d '\"')
_PUSH=

function make_build()
{
    _image=$1

    echo "Building ${_image} for ${PLATFORM_LIST} --> ${DOCKERFILE_PATH} [${_PUSH}]"
    docker buildx build \
              --platform "${PLATFORM_LIST}" \
              -f "${DOCKERFILE_PATH}" \
              -t "${_image}" \
              ${_PUSH} \
              .
}


function _main()
{

    if [[ "${MAKE_PUSH}" == "true" ]]
    then
        _PUSH="--push"
    fi

    make_build "wirepas/wm-config:latest"
    make_build "wirepas/wm-config:${BUILD_VERSION}"
}


_main
