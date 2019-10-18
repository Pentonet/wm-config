#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

# install docker if not yet present
if ! which docker
then
    if [[ "${WM_CFG_HOST_IS_RPI}" == "true" ]]
    then
        # make sure everything is upgraded before starting
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get install -y \
             apt-transport-https \
             ca-certificates \
             curl \
             gnupg2 \
             software-properties-common \
             autossh \
             gcc \
             make \
             libffi-dev \
             libssl-dev

        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88

        echo "deb [arch=armhf] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
             $(lsb_release -cs) stable" | \
             sudo tee /etc/apt/sources.list.d/docker.list

        sudo apt update
        sudo apt install -y --no-install-recommends \
            docker-ce \
            cgroupfs-mount

        sudo systemctl enable docker
        sudo systemctl start docker
    else
        # if the convenience script fails, please refer to
        # https://github.com/docker/for-linux/issues/709
        sudo curl -sSL https://get.docker.com | sh
    fi
fi

# pip
if ! which python3
then
    sudo apt-get update
    sudo apt-get install -y \
                        python3-dev \
                        python3
fi

if ! which pip3
then
    sudo apt-get install -y python3-pip
    pip3 install --upgrade pip
fi

if ! which virtualenv
then
    pip3 install --user virtualenv
fi

if [[ ! -d "${WM_CFG_PYTHON_VIRTUAL_ENV}" ]]
then
    echo "creating environment at ${WM_CFG_PYTHON_VIRTUAL_ENV}"
    virtualenv --python "${WM_CFG_PYTHON_VERSION}" "${WM_CFG_PYTHON_VIRTUAL_ENV}"
fi

