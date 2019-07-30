#!/usr/bin/env bash
# Wirepas Oy

# install docker
# if the convenience script fails, please refer to
# https://github.com/docker/for-linux/issues/709
sudo curl -sSL https://get.docker.com | sh 

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

