#!/usr/bin/env bash
# Copyright 2019 Wirepas Ltd

WM_CFG_UPDATER_WORKDIR=${WM_CFG_UPDATER_WORKDIR:-"/wm-config/updater"}
WM_CFG_UPDATER_HOSTDIR=${WM_CFG_UPDATER_HOSTDIR:-"/wm-config/host"}

echo "Updating wm-config to version: Mon 23 Sep 11:15:01 UTC 2019 - 8e77fb0"

cp -vr  "${WM_CFG_FILES}"/* "${WM_CFG_UPDATER_HOSTDIR}"
chown -R "${GW_USER}:${GW_GROUP}" "${WM_CFG_UPDATER_HOSTDIR}"

echo "update complete."
