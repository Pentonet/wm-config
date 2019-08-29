#!/usr/bin/env bash
# Wirepas Oy

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get -y install docker-ce docker-ce-cli containerd.io qemu-user-static

docker --version

docker build --platform=local -o . git://github.com/docker/buildx
mkdir -p ~/.docker/cli-plugins/
mv buildx ~/.docker/cli-plugins/docker-buildx

docker buildx create --use
