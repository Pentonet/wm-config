==================================================  ================================================================================================================================
**Variable**                                            **Definition**
==================================================  ================================================================================================================================
*WM-CONFIG execution control*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_CFG_UPDATE                                     When *true* the wm-config executable will be updated and the device will reboot (##WM_CFG_UPDATE_DEFAULT)
##WM_CFG_PULL_SETTINGS                              When *true* the wm-config will pull a settings image based on the WM_CFG_SETTINGS_IMAGE and WM_CFG_SETTINGS_VERSION (##WM_CFG_PULL_SETTINGS_DEFAULT)
##WM_CFG_REBOOT_DELAY                               Sets the amount of seconds to wait before taking an action, such as a status report (##WM_CFG_REBOOT_DELAY_DEFAULT)
##WM_CFG_HOST_INSTALL_DEPENDENCIES                  When *true* the wm-config will run (if present) /boot/wirepas/host_requiremens.sh and /boot/wirepas/requirements.txt (##WM_CFG_HOST_INSTALL_DEPENDENCIES_DEFAULT)
##WM_CFG_HOST_UPGRADE                               When *true* the wm-config will ensure all host packages are upgraded (##WM_CFG_HOST_UPGRADE_DEFAULT)
##WM_CFG_SETTINGS_IMAGE                             The registry and name of the docker image containing the wm-config settings (##WM_CFG_SETTINGS_IMAGE_DEFAULT)
##WM_CFG_SETTINGS_VERSION                           The image tag to pull (##WM_CFG_SETTINGS_VERSION_DEFAULT)
##WM_CFG_STARTUP_DELAY                              An arbitary amount of seconds to wait for the host to receive an ip (##WM_CFG_STARTUP_DELAY_DEFAULT)
##WM_CFG_SYSTEMD_UPDATER_INTERVAL                   The amount of seconds between each run of the SYSTEMD job (##WM_CFG_SYSTEMD_UPDATER_INTERVAL_DEFAULT)
##WM_HOST_AVAHI_SERVICES                            Where to source avahi services from (##WM_HOST_AVAHI_SERVICES_DEFAULT)
##WM_LXGW_DBUS_CONF_USER                            The user to give access to the wirepas services over dbus (##WM_LXGW_DBUS_CONF_USER_DEFAULT)
*Systemd jobs that oversee wm-config*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_CFG_SYSTEMD_UPDATER                            The name of the systemd job that monitors the wm-config state (##WM_CFG_SYSTEMD_UPDATER_DEFAULT)
##WM_CFG_SYSTEMD_UPDATER_DISABLE                    When *true* the systemd job will be disabled (##WM_CFG_SYSTEMD_UPDATER_DISABLE_DEFAULT)
##WM_CFG_SYSTEMD_UPDATER_ENABLE                     When *true* the systemd job will be enabled and started (##WM_CFG_SYSTEMD_UPDATER_ENABLE_DEFAULT)
*Wirepas gateway software control*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_GATEWAY                                        Which gateway software to use, lxgw or sdgw (eg, bundle installation or custom script execution) (##WM_GATEWAY_DEFAULT)
##WM_GATEWAY_STATE                                  The state of the wm-services (start/stop) (##WM_GATEWAY_STATE_DEFAULT)
##WM_GATEWAY_CLEANUP                                Ensures that all running services are terminatting before starting the selected gateway services (##WM_GATEWAY_CLEANUP_DEFAULT)
*AWS client control*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_AWS_ACCOUNT_ID                                 AWS account id tied with the aws client
##WM_AWS_REGION                                     AWS region to use with aws client (##WM_AWS_REGION_DEFAULT)
##WM_AWS_ACCESS_KEY_ID                              AWS access key to use with aws client (##WM_AWS_ACCESS_KEY_ID_DEFAULT)
##WM_AWS_SECRET_ACCESS_KEY                          AWS secret access key to use with the aws client (##WM_AWS_SECRET_ACCESS_KEY_DEFAULT)
*Docker daemon configuration*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_DOCKER_REGISTRY_LOGIN                          When true, wm-config will authenticate the Docker daemon with a remote registry (support: AWS only) (##WM_DOCKER_REGISTRY_LOGIN_DEFAULT)
##WM_DOCKER_REGISTRY                                The Docker registry from where to pull images (##WM_DOCKER_REGISTRY_DEFAULT)
##WM_DOCKER_CLEANUP                                 Forces a cleanup of all running docker containers and performs a system prune (##WM_DOCKER_CLEANUP_DEFAULT)
##WM_DOCKER_FORCE_RECREATE                          Ensures that containers are recreated whenever the services are restored (##WM_DOCKER_FORCE_RECREATE_DEFAULT)
##WM_DOCKER_STATUS_DELAY                            The amount of seconds to wait before printing the status of the docker containers (##WM_DOCKER_STATUS_DELAY_DEFAULT)
##WM_DOCKER_CONFIGURE_DAEMON                        When true, wm-config will attempt to configure the docker dameon with the JSON present in WM_DOCKER_DAEMON_JSON (##WM_DOCKER_CONFIGURE_DAEMON_DEFAULT)
##WM_DOCKER_DAEMON_JSON                             The JSON text to configure the docker daemon with (##WM_DOCKER_DAEMON_JSON_DEFAULT)
*Wirepas Linux Gateway*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_LXGW_IMAGE                                     The name of the WM Gateway Docker image to pull (##WM_LXGW_IMAGE_DEFAULT)
##WM_LXGW_VERSION                                   The tag associated with the WM Gateway image (##WM_LXGW_VERSION_DEFAULT)
##WM_LXGW_DBUS_CONF                                 The DBUS configuration file to be present in the host environment (##WM_LXGW_DBUS_CONF_DEFAULT)
##WM_LXGW_SINK_SERVICE_CMD                          The sink command to use with the sink service (##WM_LXGW_SINK_SERVICE_CMD_DEFAULT)
##WM_LXGW_TRANSPORT_SERVICE_CMD                     The transport command to use with the transport service (##WM_LXGW_TRANSPORT_SERVICE_CMD_DEFAULT)
*Custom Gateway*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_SDGW_TAR_PATH                                  Path to a tar which will be extracted and brough up by docker compose if a run script is not present (##WM_SDGW_TAR_PATH_DEFAULT)
##WM_SDGW_SCRIPT_PATH                               The path to a generic script to handle the start of a gateway service or any other host job (##WM_SDGW_SCRIPT_PATH_DEFAULT)
*Wirepas sink settings*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_ENABLE_SERIAL_SYMLINKS                         When true, the wm-config will ensure Wirepas complaint devices are known with a given alias (##WM_ENABLE_SERIAL_SYMLINKS_DEFAULT)
##WM_SERIAL_NICKNAME                                The serial alias to associate with a Wirepas complaint device attached to the host (##WM_SERIAL_NICKNAME_DEFAULT)
##WM_FORCE_UART_PORT                                Force the designated port to be used with the sink service (##WM_FORCE_UART_PORT_DEFAULT)
##WM_SINK_ID                                        The pseudo id of the sink served by the sink service (##WM_SINK_ID_DEFAULT)
##WM_SINK_UART_PORT                                 The default sink port (##WM_SINK_UART_PORT_DEFAULT)
##WM_SINK_UART_BITRATE                              The baudrate to use when communicating with the sink device (##WM_SINK_UART_BITRATE_DEFAULT)
*MQTT broker*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_SERVICES_HOST                                  A hostname where to push the gateway data, eg, MQTT broker hostname or ip (##WM_SERVICES_HOST_DEFAULT)
##WM_SERVICES_MQTT_PORT                             Defines the MQTT port to use (unsecure 1883, secure 8883) (##WM_SERVICES_MQTT_PORT_DEFAULT)
##WM_SERVICES_MQTT_USER                             The device's MQTT username (##WM_SERVICES_MQTT_USER_DEFAULT)
##WM_SERVICES_MQTT_PASSWORD                         The device's MQTT password (##WM_SERVICES_MQTT_PASSWORD_DEFAULT)
##WM_SERVICES_TLS_ENABLED                           When true, a secure connection will be established (##WM_SERVICES_TLS_ENABLED_DEFAULT)
##WM_SERVICES_ALLOW_UNSECURE                        When ture, allows an unsecure connection to be established (##WM_SERVICES_ALLOW_UNSECURE_DEFAULT)
##WM_SERVICES_CERTIFICATE_CHAIN                     The path to the CA certificate (##WM_SERVICES_CERTIFICATE_CHAIN_DEFAULT)
*Gateway metadata*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_SERVICES_GATEWAY_ID                            The id used to identifying the gateway at the MQTT level (##WM_SERVICES_GATEWAY_ID_DEFAULT)
##WM_SERVICES_GATEWAY_MODEL                         Metadata about the gateway model (##WM_SERVICES_GATEWAY_MODEL_DEFAULT)
##WM_SERVICES_GATEWAY_VERSION                       Metadata about the gateway version (##WM_SERVICES_GATEWAY_VERSION_DEFAULT)
##WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER      List of endpoints that should not be published to the MQTT broker (##WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER_DEFAULT)
##WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER     List of endpoints whose payload should be zeroed out when published to the broker (##WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER_DEFAULT)
*Wirepas support settings*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_SUPPORT_HOST_NAME                              For Wirepas support (##WM_SUPPORT_HOST_NAME_DEFAULT)
##WM_SUPPORT_HOST_KEY                               For Wirepas support (##WM_SUPPORT_HOST_KEY_DEFAULT)
##WM_SUPPORT_HOST_KEY_PATH                          For Wirepas support (##WM_SUPPORT_HOST_KEY_PATH_DEFAULT)
##WM_SUPPORT_HOST_PORT                              For Wirepas support (##WM_SUPPORT_HOST_PORT_DEFAULT)
##WM_SUPPORT_HOST_USER                              For Wirepas support (##WM_SUPPORT_HOST_USER_DEFAULT)
*Host settings*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_HOST_SET_HOSTNAME                              Sets the hostname of the host (##WM_HOST_SET_HOSTNAME_DEFAULT)
##WM_HOST_SSH_ENABLE_NETWORK_LOGIN                  Enables ssh login using plain text passwords (Raspi only) (##WM_HOST_SSH_ENABLE_NETWORK_LOGIN_DEFAULT)
##WM_HOST_IPV6_DISABLE                              Blacklists the IPv6 module and reboots the host (##WM_HOST_IPV6_DISABLE_DEFAULT)
##WM_HOST_SET_KEYBOARD                              Sets the host's keyboard (##WM_HOST_SET_KEYBOARD_DEFAULT)
##WM_HOST_KEYBOARD_XKBMODEL                         Defines the host's keyboard model (##WM_HOST_KEYBOARD_XKBMODEL_DEFAULT)
##WM_HOST_KEYBOARD_XKBLAYOUT                        Defines the host's keyboard layout (##WM_HOST_KEYBOARD_XKBLAYOUT_DEFAULT)
##WM_HOST_KEYBOARD_XKBVARIANT                       Defines the host's keyboard variant (##WM_HOST_KEYBOARD_XKBVARIANT_DEFAULT)
##WM_HOST_KEYBOARD_XKBOPTIONS                       Defines the host's keyboard options (##WM_HOST_KEYBOARD_XKBOPTIONS_DEFAULT)
##WM_HOST_KEYBOARD_BACKSPACE                        Defines the host's keyboard backspace (##WM_HOST_KEYBOARD_BACKSPACE_DEFAULT)
##WM_HOST_USER_NAME                                 The username of the host's admin user (##WM_HOST_USER_NAME_DEFAULT)
##WM_HOST_USER_PASSWORD                             The password of the host's admin user (##WM_HOST_USER_PASSWORD_DEFAULT)
##WM_HOST_USER_PPKI                                 The public key to authorize in the ssh authorized keys (##WM_HOST_USER_PPKI_DEFAULT)
##WM_WIFI_DISABLE                                   When true, configures the wifi client to connect ot the specified SSID (##WM_WIFI_DISABLE_DEFAULT)
##WM_WIFI_AP_SSID                                   The WiFi SSID to connect to (##WM_WIFI_AP_SSID_DEFAULT)
##WM_WIFI_AP_PASSWORD                               The WiFi's SSID password (##WM_WIFI_AP_PASSWORD_DEFAULT)
##WM_RPI_EXPAND_FILESYSTEM                          When true expands the raspi filesystem (##WM_RPI_EXPAND_FILESYSTEM_DEFAULT)
*Web services integration*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##WM_SLACK_WEBHOOK                                  A slack webhook where to post information about the wm-config execution (##WM_SLACK_WEBHOOK_DEFAULT)
##WM_MSTEAMS_WEBHOOK                                A microsoft teams webhook where to post information about the wm-config execution (##WM_MSTEAMS_WEBHOOK_DEFAULT)
==================================================  ================================================================================================================================

