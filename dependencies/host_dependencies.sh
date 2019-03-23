#!/usr/bin/env bash
# Wirepas Oy

# install docker
sudo curl -sSL https://get.docker.com | sh

# pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo -H python3 get-pip.py
sudo rm get-pip.py

sudo apt-get update

sudo apt-get install autossh -y

