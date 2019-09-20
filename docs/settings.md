<!-- auto_start -->
# List of settings

The following table contains the full set of environmental keys used by wm-config.

With the exception of the discovered and static variables, all the variables are
found from the default settings file.

Please understand that certain settings might break the functionality of the services
and alter the state of your host.

The framework will only reboot the host device if it is a RPi. Otherwise, you should
perform a reboot when and if asked for one.

## Host and dependency management

| _WM-CONFIG discovered variables_   |                                                                                                                                                                               |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **WM_CFG_HOST_ARCH**               | Host architecture                                                                                                                                                             |
| **WM_CFG_HOST_MODEL**              | Host model                                                                                                                                                                    |
| **WM_CFG_HOST_IS_RPI**             | True when running on a RPi                                                                                                                                                    |
| ---                                | ---                                                                                                                                                                           |
| _WM-CONFIG static variables_       |                                                                                                                                                                               |
| ---                                | ---                                                                                                                                                                           |
| **WM_CFG_VERSION**                 | Current WM-CONFIG version in use                                                                                                                                              |
| **WM_CFG_ENTRYPOINT**              | Path where to copy the shell entrypoint (./bin/wm-config.sh) ('default:${HOME}/.local/bin/wm-config')                                                                         |
| **WM_CFG_INSTALL_PATH**            | Directory where wm-config files will be copied to (default: '${HOME}/.local/wirepas/wm-config')                                                                               |
| **WM_CFG_SETTINGS_PATH**           | Path where settings will be sourced from (default: /boot/wirepas for RPi and '${HOME}/wirepas/wm-config' for others )                                                         |
| **WM_CFG_SETTINGS_DEFAULT**        | Path to the default settings file (default: '${WM_CFG_SETTINGS_PATH}/default.env')                                                                                            |
| **WM_CFG_SETTINGS_CUSTOM**         | Path to the default settings file (default: '${WM_CFG_SETTINGS_PATH}/custom.env')                                                                                             |
| **WM_CFG_SUDO**                    | Command to gain privileged access (default: sudo)                                                                                                                             |
| **WM_CFG_HOST_PATH**               | Path with files that will be copied to the host environment and dependency description (default: '${WM_CFG_INSTALL_PATH}/host')                                               |
| **WM_CFG_UPDATE_PATH**             | Path used by the container to copy updated files (default: '${WM_CFG_INSTALL_PATH}/update')                                                                                   |
| **WM_CFG_TEMPLATE_PATH**           | Path where to lookup template files. The templates are files that will be generated based on the current host's environment (default: '${WM_CFG_INSTALL_PATH}/templates')     |
| **WM_CFG_SESSION_STORAGE_PATH**    | Path where session logs are stored to (default: '${WM_CFG_SETTINGS_PATH}/.session')                                                                                           |
| ---                                | ---                                                                                                                                                                           |
| _WM-CONFIG runtime configuration_  |                                                                                                                                                                               |
| ---                                | ---                                                                                                                                                                           |
| **WM_HOST_INSTALL_DEPENDENCIES** | When _true_ the wm-config will run (if present) ${WM_CFG_HOST_PATH}/host_requiremens.sh and ${WM_CFG_HOST_PATH}/requirements.txt (##WM_CFG_HOST_INSTALL_DEPENDENCIES_DEFAULT) |
| **WM_HOST_UPGRADE_PACKAGES**              | When _true_ the wm-config will ensure all host packages are upgraded (##WM_CFG_HOST_UPGRADE_DEFAULT)                                                                          |
| **WM_CFG_STARTUP_DELAY**             | Sets the amount of seconds to delay the execution of wm-config (*default=0*)                                                                               |
| **WM_CFG_REBOOT_DELAY**              | Sets the amount of seconds to wait before taking an action, such as a status report (*default=2*)                                                           |
| **WM_CFG_PYTHON_VERSION**            | Python version to use when creating the virtual environment (*default=python3*)                                                                                 |
| **WM_CFG_PYTHON_VIRTUAL_ENV**        | Path where to create or find the python virtual environment where to install the wm-config dependencies (*default=/home/silva/.local/virtualenv/wm-config*)                                 |
| **WM_CFG_WEBHOOK_POST_URL**          | A webhook where to post information about the wm-config execution (*default=unset*)                                                                         |
| ---                                | ---                                                                                                                                                                           |
| _WM-CONFIG updater_                | ---                                                                                                                                                                           |
| ---                                | ---                                                                                                                                                                           |
| **WM_CFG_UPDATE**                    | **DEPRECATE?** When _true_ the wm-config executable will be updated and the device will reboot (*default=true*)                                                      |
| **WM_CFG_FRAMEWORK_UPDATE**             | **DEPRECATE?** When _true_ the wm-config will pull a settings image based on the WM_CFG_UPDATER_IMAGE and WM_CFG_UPDATER_VERSION (*default=false*)             |
| **WM_CFG_UPDATER_VERSION**           | The wm-config release version to pull - image's tag  (*default=latest*)                                                                                       |
| **WM_CFG_UPDATER_IMAGE**             | The registry and name of the docker image containing the wm-config files (*default=wirepas/wm-config*)                                                                     |
| ---                                | ---                                                                                                                                                                           |
| _Docker daemon configuration_      |                                                                                                                                                                               |
| ---                                | ---                                                                                                                                                                           |
| **WM_DOCKER_STATUS_DELAY**           | The amount of seconds to wait before displaying the gateway service status (*default=30*)                                                                 |
| **WM_DOCKER_USERNAME**               | The user name to use when logging in with Docker (*default=unset*)                                                                                               |
| **WM_DOCKER_PASSWORD**               | The user's password to use when logging in with docker (*default=unset*)                                                                                         |
| **WM_DOCKER_DAEMON_JSON**            | **Advanced** The JSON text to configure the docker daemon with (*default=unset*)                                                                              |
| **WM_DOCKER_CLEANUP**                | Forces a cleanup of all running docker containers and performs a system prune  (*default=true*)                                                                  |
| **WM_DOCKER_FORCE_RECREATE**         | Ensures that containers are recreated whenever the services state is monitored (*default=false*)                                                           |

## Gateway and data broker settings

| _MQTT broker settings_                          |                                                                                                                                                                |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **WM_SERVICES_MQTT_HOSTNAME**                              | A host where to push the gateway data, eg, MQTT broker hostname or ip  (*default=host.extwirepas.com*)                                                            |
| **WM_SERVICES_MQTT_USER**                         | The MQTT username (*default=mqttuser*)                                                                                                            |
| **WM_SERVICES_MQTT_PASSWORD**                     | The MQTT's username password corresponding (*default=uiaidujfk1897fyeu023849sdh?(*)                                                                               |
| **WM_SERVICES_MQTT_PORT**                         | Defines the MQTT port to use (unsecure 1883, secure 8883) (*default=8883*)                                                                    |
| **WM_SERVICES_ALLOW_UNSECURE**                    | Must be set to true to allow unsecure connections, eg, to port 1883 (*default=unset*)                                                     |
| **WM_SERVICES_CERTIFICATE_CHAIN**                 | The container path where to find the root ca certificates (*default=unset*)                                                            |
| ---                                             | ---                                                                                                                                                            |
| _Gateway metadata, transport and sink service_  |                                                                                                                                                                |
| ---                                             | ---                                                                                                                                                            |
| **WM_GW_STATE**                     | The state of the gateway services to enforce (start/stop) (*default=start*)                                                                |
| **WM_GW_ID**                        | The id used to identifying the gateway at the MQTT level (*default=pos-silva*)                                                                    |
| **WM_GW_MODEL**                     | Metadata about the gateway model (*default=wirepas-evk*)                                                                                         |
| **WM_GW_VERSION**                   | Metadata about the gateway version (*default=latest*)                                                                                     |
| **WM_GW_WHITENED_ENDPOINTS_FILTER** | List of endpoints whose payload should be zeroed out when published to the broker  (*default=unset*)                   |
| **WM_GW_IGNORED_ENDPOINTS_FILTER**  | List of endpoints that should not be published to the MQTT broker (*default=unset*)                                     |
| **WM_GW_IMAGE**                                 | The name of the WM Gateway Docker image to pull  (*default=wirepas/gateway*)                                                                                     |
| **WM_GW_VERSION**                               | The build or docker tag to use (*default=latest*)                                                                                                     |
| **WM_GW_SERVICES_USER_PATH**                    | **Advanced** The path to create and overlay within the containers (*default=/user*)                                                       |
| **WM_GW_SERVICES_ENV_FILE**                     | **Advanced** Location of the environment file used by the transport and sink service (*default=/services.env*)                                     |
| **WM_GW_TRANSPORT_SERVICE_CMD**                 | **Advanced** The command to use with the transport service container (*default=transport*)                                                 |
| **WM_GW_TRANSPORT_SERVICE_NETWORK**             | **Advanced** The network where to attach the transport service container (*default=network_mode:*)                                         |
| **WM_GW_SINK_SERVICE_CMD**                      | **Advanced** The command to use with the sink service container (*default=sink*)                                                           |
| **WM_GW_SINK_PORT_RULE**                        | **Advanced** The sink ports to use during the auto enumerate (*default=/dev/ttyACM**)                                                                |
| **WM_GW_SINK_BLACKLIST**                        | **Advanced** A patter or device to ignore during the auto enumeration (*default=unset*)                                                       |
| **WM_GW_SINK_BITRATE_CONFIGURATION**            | **Advanced** An array with the bitrate to use for a given sink. The sink id will match the array index (*default=unset*)          |
| **WM_GW_DBUS_CONF**                             | **Advanced** The DBUS configuration file to be present in the host environment (*default=com.wirepas.sink.conf*)                                                   |
| **WM_GW_DBUS_CONF_USER**                        | **Advanced** The user that should be set within the DBUS configuration (*default=root*)                                                      |
| ---                                             | ---                                                                                                                                                            |
| ##WM_SINK_UART_BITRATE                          | **DEPRECATE?** The baudrate to use when communicating with the sink device (##WM_SINK_UART_BITRATE_DEFAULT)                                                    |
| **WM_GW_SINK_UART_PORT**                        | **DEPRECATE?** The port where a Wirepas sink can be found from (*default=/dev/ttyWM*)                                                              |
| **WM_GW_SINK_ID**                               | **DEPRECATE?** The pseudo id of the sink served by the sink service (*default=0*)                                                                |
| **WM_HOST_TTY_SYMLINK**                                | **DEPRECATE?** The serial alias to associate with a Wirepas complaint device attached to the host (*default=ttyWM*)                                   |
| **WM_GW_SINK_ENUMERATION**                   | **DEPRECATE?** Set to true to enable the automatic enumeration of tty ports - removes the need to specify a given port (##WM_GW_ENUMERATE_TTY_PORTS_DEFAULT) |

## Raspberry Pi specific

| _Filesystem and access control_            |                                                                                                   |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| **WM_HOST_EXPAND_FILESYSTEM**                 | When true expands the raspi filesystem  (##WM_RPI_EXPAND_FILESYSTEM_DEFAULT)                      |
| **WM_HOST_HOSTNAME**                     | Sets the hostname of the host (##WM_HOST_SET_HOSTNAME_DEFAULT)                                    |
| **WM_HOST_USER_NAME**                        | The username of the host's admin user (*default=pi*)                               |
| **WM_HOST_USER_PASSWORD**                    | The password of the host's admin user (*default=unset*)                           |
| **WM_HOST_USER_PPKI**                        | The public key to authorize in the ssh authorized keys (*default=unset*)              |
| **WM_HOST_SSH_ENABLE_NETWORK_LOGIN**         | Enables ssh login using plain text passwords (*default=true*)         |
| ---                                        | ---                                                                                               |
| _Periodic job control (requires systemd) _ |                                                                                                   |
| ---                                        | ---                                                                                               |
| **WM_SYSTEMD_UPDATER**                   | The name of the systemd job that monitors the wm-config state (*default=wirepas-updater*)  |
| **WM_SYSTEMD_UPDATER_INTERVAL**          | (*default=15552000*)                                                       |
| **WM_SYSTEMD_UPDATER_ENABLE**            | When _true_ the systemd job will be enabled and started (*default=true*) |
| **WM_SYSTEMD_UPDATER_DISABLE**           | When _true_ the systemd job will be disabled (*default=false*)           |
| ---                                        | ---                                                                                               |
| _Internet connectivity_                    |                                                                                                   |
| ---                                        | ----                                                                                              |
| **WM_HOST_IPV6_DISABLE**                     | Blacklists the IPv6 module and reboots the host (*default=false*)                  |
| **WM_WIFI_ENABLE**                          | When true forces the WiFi interface to be down  (##WM_WIFI_DISABLE_DEFAULT)                       |
| **WM_WIFI_AP_SSID**                          | The WiFi SSID where the host should connect to (*default=unset*)                        |
| **WM_WIFI_AP_PASSWORD**                      | The WiFi's SSID password (*default=unset*)                                          |
| ---                                        | ---                                                                                               |
| _For Wirepas support_                      |                                                                                                   |
| ---                                        | ---                                                                                               |
| **WM_SUPPORT_HOST_PORT**                     | For Wirepas support (*default=unset*)                                              |
| **WM_SUPPORT_HOST_NAME**                     | For Wirepas support (*default=host.extwirepas.com*)                                              |
| **WM_SUPPORT_HOST_KEY**                      | For Wirepas support (*default=/support.pem*)                                               |
| **WM_SUPPORT_HOST_USER**                     | For Wirepas support (*default=silva*)                                              |
| **WM_SUPPORT_HOST_KEY_PATH**                 | For Wirepas support (*default=/home/silva/.ssh/support.pem*)                                          |
| ---                                        | ---                                                                                               |
| _Keyboard settings_                        |                                                                                                   |
| ---                                        | ---                                                                                               |
| **WM_HOST_KEYBOARD_CONFIGURE**                     | Sets the host's keyboard (##WM_HOST_SET_KEYBOARD_DEFAULT)                                         |
| **WM_HOST_KEYBOARD_XKBMODEL**                | Defines the host's keyboard model (*default=pc105*)                           |
| **WM_HOST_KEYBOARD_BACKSPACE**               | Defines the host's keyboard backspace (*default=guess*)                      |
| **WM_HOST_KEYBOARD_XKBOPTIONS**              | Defines the host's keyboard options (*default=unset*)                       |
| **WM_HOST_KEYBOARD_XKBLAYOUT**               | Defines the host's keyboard layout (*default=gb*)                         |
| **WM_HOST_KEYBOARD_XKBVARIANT**              | Defines the host's keyboard variant (*default=unset*)                       |
| **WM_HOST_AVAHI_SERVICES**                   | Where to source avahi services from (*default=/ssh.service*)                            |

<!--- bound for deprecation

| **Variable**         | **Definition**                 |
| --- | --- |
| ##WM_DOCKER_REGISTRY | (##WM_DOCKER_REGISTRY_DEFAULT) |
| ### BITRATE_CONFIGURATION
| ##WM_SINK_UART_BITRATE      | The baudrate to use when communicating with the sink device (##WM_SINK_UART_BITRATE_DEFAULT)

 -->
<!-- auto_end -->
