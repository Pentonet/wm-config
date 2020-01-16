#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

set -e

# install docker if not yet present
if ! command -v docker
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
        sudo curl -fsSL https://get.docker.com -o "${HOME}/get-docker.sh"
        sudo sh "${HOME}/get-docker.sh"
        sudo rm -f "${HOME}/get-docker.sh"
    fi
fi

# These must be met
sudo apt-get update
sudo apt-get install -y \
                    python3 \
                    python3-dev 
sudo apt-get install -y python3-distutils || true

if ! command -v pip3
then
    sudo curl https://bootstrap.pypa.io/get-pip.py -o "${HOME}/get-pip.py"
    sudo chown "${USER}:${USER}" "${HOME}/get-pip.py"
    python3 "${HOME}/get-pip.py" --user
    sudo rm -f "${HOME}/get-pip.py"
fi

if ! command -v virtualenv
then
    python3 -m pip install --user virtualenv
fi

if [[ ! -f "${WM_CFG_PYTHON_VIRTUAL_ENV}/bin/activate" ]]
then
    echo "creating environment at ${WM_CFG_PYTHON_VIRTUAL_ENV}"
    mkdir -pv "${WM_CFG_PYTHON_VIRTUAL_ENV}"
    virtualenv --python "${WM_CFG_PYTHON_VERSION}" "${WM_CFG_PYTHON_VIRTUAL_ENV}"
fi

