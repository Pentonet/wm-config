#!/usr/bin/env bash
# Wirepas Oy

# make sure everything is upgraded before starting
sudo apt-get update
sudo apt-get upgrade -y

# install docker from the repositories for raspbian
if [[ "${HOST_IS_RPI}" == "true" ]]
then
    sudo apt-get update
    sudo apt-get install \
         apt-transport-https \
         ca-certificates \
         curl \
         gnupg2 \
         software-properties-common

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

# pip
sudo apt-get update
sudo apt-get install -y autossh \
                      gcc \
                      libffi-dev \
                      libssl-dev \
                      make \
                      python3-dev \
                      python3 \
                      python3-pip

pip3 install --upgrade pip

