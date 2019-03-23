#!/usr/bin/env bash
# Wirepas Oy

set -x
echo "configurator version #FILLVERSION"

WM_GFG_SETTINGS_PATH="/home/wirepas/settings"

echo "updating templates and services"
cp -r  ${WM_GFG_SETTINGS_PATH}/* /opt/settings/
chown -R ${GW_USER}:${GW_GROUP} /opt/settings

echo "updated"
