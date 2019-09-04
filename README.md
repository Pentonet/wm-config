# wm-config

The Wirepas Host Configurator (wm-config) is a [command line tool][here_bin_wmconfig]
which configures a host computer to allow it to run the Wirepas gateway software.

## Creating a configuration file

wm-config receives its configuration through an environment file located on its [settings
entrypoint path (WM_ENVIRONMENT_CUSTOM)][here_entrypoint_settings].

The configuration file allows you to specify important settings such as which
gateway version to run, which broker to connect to, user credentials, as well as
other system configurations. See [environment/custom.env][here_environment_custom] for an example file.

Values set in *custom.env* will override any default value set within [default.env][here_environment_default].

## Installation

To install the wm-config clone this repository, checkout [a release tag][here_releases] and run

```shell
	./setup.sh false
```

The repository files will be copied under [WM_SERVICE_HOME][here_bin_wmconfig_service_home]. Copy your custom.env
file inside the path [WM_ENVIRONMENT_CUSTOM][here_entrypoint_settings] and call the tool with

```shell
  wm-config
```

### Creating an installation bundle

An archive bundle is useful to share accross multiple hosts without having to
install and clone the repository N times.

To build an archive, clone the repository on a machine with bash and run the
following script:

```shell
	./pack.sh
```

The pack.sh will create an archive under *./deliverable/wm-config.tar.gz*.

Copy the archive, the setup.sh and your custom.env to your host's home directory

```shell

  scp ./deliverable/wm-config.tar.gz <user>@<ip>:
  scp ./deliverable/setup.sh <user>@<ip>:
  scp ./deliverable/custom.env <user>@<ip>:

  ssh <user>@<ip>
  ./setup.sh

```

The setup script will create the directory [WM_SERVICE_HOME][here_bin_wmconfig_service_home], extract the
bundle's contents, copy the custom.env to its correct path and call *wm-config*.

## Runtime operation

Upon startup, wm-config will source the modules (see [/modules][here_modules]) and
evaluate the [default][here_environment_default] and [custom environment][here_environment_custom]
files (on a rpi the settings entrypoint for the custom.env file is */boot/wirepas/custom.env*).

The environment keys will define the wm-config's behaviour and execute the
necessary management of the host, including rebooting when necessary.

![runtime operation of wm-config][here_docs_operation]

**Figure 1:** provides an overview of the steps taken by wm-config.

To monitor the status of wm-config you can rely on systemctl, journalctl and the docker commands.

With systemctl type on the host's shell

```shell
    systemctl status wirepas-updater
```

which will show you the current status of the service.

With journalctl type on the host's shell

```shell
    journalctl -fu wirepas-updater
```

which will present you the latest status of the service and keep tracking
it (-f).

The name of the service is in fact the one specified in WM_CFG_SYSTEMD_UPDATER
which defaults to wirepas-updater.

To inspect the status of the gateway services, you can rely on several docker and docker-compose
commands such as:

```shell
   docker ps : to view the status of the services

   docker logs <container name>
```

With docker compose either change directory to [WM_SERVICE_HOME][here_bin_wmconfig_service_home]
or set the compose file path appropiately:

```shell
   docker-compose [ -f <WM_SERVICE_HOME>/lxgw/docker-compose.yml ] ps

   docker-compose [ -f <WM_SERVICE_HOME>/lxgw/docker-compose.yml ] logs

```

If you wish to stop, start the services you should interact with wm-config by setting
the state flag value when calling wm-config

```shell
   wm-config [ --state start/stop ]
```

### Environment keys

The custom and default environment files can contain any of the following keys.
It is not recommended to change the default environment file as it will be
overwritten by updates.

Any environment customization should be done within the custom environment file,
residing in the [WM_ENTRYPOINT_SETTINGS path][here_entrypoint_settings]. The default value is controled
by the [executable itself][here_entrypoint_settings].

<!-- table_start -->

| **Variable**                                      | **Definition**                                                                                                                        |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **WM-CONFIG execution control**                   | **Definition**                                                                                                                        |
| **WM_CFG_UPDATE**                                 | When *true* the wm-config executable will be updated and the device will reboot (*default=true*)                                      |
| **WM_CFG_PULL_SETTINGS**                          | When *true* the wm-config will pull a settings image based on the WM_CFG_SETTINGS_IMAGE and WM_CFG_SETTINGS_VERSION (*default=false*) |
| **WM_CFG_REBOOT_DELAY**                           | Sets the amount of seconds to wait before taking an action, such as a status report (*default=10*)                                    |
| **WM_CFG_HOST_INSTALL_DEPENDENCIES**              | When *true* the wm-config will run (if present) /boot/wirepas/host_requiremens.sh and /boot/wirepas/requirements.txt (*default=true*) |
| **WM_CFG_HOST_UPGRADE**                           | When *true* the wm-config will ensure all host packages are upgraded (*default=true*)                                                 |
| **WM_CFG_SETTINGS_IMAGE**                         | The registry and name of the docker image containing the wm-config settings (*default=wirepas/gateway-settings-rpi*)                  |
| **WM_CFG_SETTINGS_VERSION**                       | The image tag to pull (*default=latest*)                                                                                              |
| **WM_CFG_STARTUP_DELAY**                          | An arbitary amount of seconds to wait for the host to receive an ip (*default=80*)                                                    |
| **WM_CFG_SYSTEMD_UPDATER_INTERVAL**               | The amount of seconds between each run of the SYSTEMD job (*default=86400*)                                                           |
| **WM_HOST_AVAHI_SERVICES**                        | Where to source avahi services from (*default=/ssh.service*)                                                                          |
| **WM_LXGW_DBUS_CONF_USER**                        | The user to give access to the wirepas services over dbus (*default=root*)                                                            |
| **Systemd jobs that oversee wm-config**           |                                                                                                                                       |
| **WM_CFG_SYSTEMD_UPDATER**                        | The name of the systemd job that monitors the wm-config state (*default=wirepas-updater*)                                             |
| **WM_CFG_SYSTEMD_UPDATER_DISABLE**                | When *true* the systemd job will be disabled (*default=false*)                                                                        |
| **WM_CFG_SYSTEMD_UPDATER_ENABLE**                 | When *true* the systemd job will be enabled and started (*default=true*)                                                              |
| **Wirepas gateway software control**              |                                                                                                                                       |
| **WM_GATEWAY**                                    | Which gateway software to use, lxgw or sdgw (eg, bundle installation or custom script execution) (*default=lxgw*)                     |
| **WM_GATEWAY_STATE**                              | The state of the wm-services (start/stop) (*default=start*)                                                                           |
| **WM_GATEWAY_CLEANUP**                            | Ensures that all running services are terminatting before starting the selected gateway services (*default=false*)                    |
| **AWS client control**                            |                                                                                                                                       |
| **WM_AWS_ACCOUNT_ID**                             | AWS account id tied with the aws client                                                                                               |
| **WM_AWS_REGION**                                 | AWS region to use with aws client (*default=unset*)                                                                                   |
| **WM_AWS_ACCESS_KEY_ID**                          | AWS access key to use with aws client (*default=unset*)                                                                               |
| **WM_AWS_SECRET_ACCESS_KEY**                      | AWS secret access key to use with the aws client (*default=unset*)                                                                    |
| **Docker daemon configuration**                   |                                                                                                                                       |
| **WM_DOCKER_REGISTRY_LOGIN**                      | When true, wm-config will authenticate the Docker daemon with a remote registry (support: AWS only) (*default=false*)                 |
| **WM_DOCKER_REGISTRY**                            | The Docker registry from where to pull images (*default=wirepas*)                                                                     |
| **WM_DOCKER_CLEANUP**                             | Forces a cleanup of all running docker containers and performs a system prune (*default=true*)                                        |
| **WM_DOCKER_FORCE_RECREATE**                      | Ensures that containers are recreated whenever the services are restored (*default=false*)                                            |
| **WM_DOCKER_STATUS_DELAY**                        | The amount of seconds to wait before printing the status of the docker containers (*default=30*)                                      |
| **WM_DOCKER_CONFIGURE_DAEMON**                    | When true, wm-config will attempt to configure the docker dameon with the JSON present in WM_DOCKER_DAEMON_JSON (*default=false*)     |
| **WM_DOCKER_DAEMON_JSON**                         | The JSON text to configure the docker daemon with (*default=unset*)                                                                   |
| **Wirepas Linux Gateway - Docker Installation**   |                                                                                                                                       |
| **WM_LXGW_IMAGE**                                 | The name of the WM Gateway Docker image to pull (*default=wirepas/gateway*)                                                           |
| **WM_LXGW_VERSION**                               | The tag associated with the WM Gateway image (*default=latest*)                                                                       |
| **WM_LXGW_DBUS_CONF**                             | The DBUS configuration file to be present in the host environment (*default=com.wirepas.sink.conf*)                                   |
| **WM_LXGW_SINK_SERVICE_CMD**                      | The sink command to use with the sink service (*default=sink*)                                                                        |
| **WM_LXGW_TRANSPORT_SERVICE_CMD**                 | The transport command to use with the transport service (*default=transport*)                                                         |
| **Custom Gateway**                                |                                                                                                                                       |
| **WM_SDGW_TAR_PATH**                              | Path to a tar which will be extracted and brough up by docker compose if a run script is not present (*default=/wm-gateway.tar.gz*)   |
| **WM_SDGW_SCRIPT_PATH**                           | The path to a generic script to handle the start of a gateway service or any other host job (*default=/run.sh*)                       |
| **Wirepas sink settings**                         | (sinks are auto enumerated from version 1.2.0 onwards)                                                                                |
| **WM_ENABLE_SERIAL_SYMLINKS**                     | When true, the wm-config will ensure Wirepas complaint devices are known with a given alias (*default=true*)                          |
| **WM_SERIAL_NICKNAME**                            | The serial alias to associate with a Wirepas complaint device attached to the host (*default=ttyWM*)                                  |
| **WM_FORCE_UART_PORT**                            | Force the designated port to be used with the sink service (*default=unset*)                                                          |
| **WM_SINK_ID**                                    | The pseudo id of the sink served by the sink service (*default=0*)                                                                    |
| **WM_SINK_UART_PORT**                             | The default sink port (*default=/dev/ttyWM*)                                                                                          |
| **WM_SINK_UART_BITRATE**                          | The baudrate to use when communicating with the sink device (*default=125000*)                                                        |
| **MQTT broker**                                   |                                                                                                                                       |
| **WM_SERVICES_HOST**                              | A hostname where to push the gateway data, eg, MQTT broker hostname or ip (*default=host.extwirepas.com*)                             |
| **WM_SERVICES_MQTT_PORT**                         | Defines the MQTT port to use (unsecure 1883, secure 8883) (*default=8883*)                                                            |
| **WM_SERVICES_MQTT_USER**                         | The device's MQTT username (*default=mqttuser*)                                                                                       |
| **WM_SERVICES_MQTT_PASSWORD**                     | The device's MQTT password (*default=uiaidujfk1897fyeu023849sdh?(*)                                                                   |
| **WM_SERVICES_TLS_ENABLED**                       | When true, a secure connection will be established (*default=True*)                                                                   |
| **WM_SERVICES_ALLOW_UNSECURE**                    | When true, allows an unsecure connection to be established (*default=unset*)                                                          |
| **WM_SERVICES_CERTIFICATE_CHAIN**                 | The path to the CA certificate (*default=/etc/extwirepas.pem*)                                                                        |
| **Gateway metadata**                              |                                                                                                                                       |
| **WM_SERVICES_GATEWAY_ID**                        | The id used to identifying the gateway at the MQTT level (*default=`hostname`*)                                                       |
| **WM_SERVICES_GATEWAY_MODEL**                     | Metadata about the gateway model (*default=unset*)                                                                                    |
| **WM_SERVICES_GATEWAY_VERSION**                   | Metadata about the gateway version (*default=unset*)                                                                                  |
| **WM_SERVICES_GATEWAY_IGNORED_ENDPOINTS_FILTER**  | List of endpoints that should not be published to the MQTT broker (*default=unset*)                                                   |
| **WM_SERVICES_GATEWAY_WHITENED_ENDPOINTS_FILTER** | List of endpoints whose payload should be zeroed out when published to the broker (*default=unset*)                                   |
| **Wirepas support settings**                      |                                                                                                                                       |
| **WM_SUPPORT_HOST_NAME**                          | For Wirepas support (*default=host.extwirepas.com*)                                                                                   |
| **WM_SUPPORT_HOST_KEY**                           | For Wirepas support (*default=/support.pem*)                                                                                          |
| **WM_SUPPORT_HOST_KEY_PATH**                      | For Wirepas support (*default=${HOME}/.ssh/support.pem*)                                                                              |
| **WM_SUPPORT_HOST_PORT**                          | For Wirepas support (*default=unset*)                                                                                                 |
| **WM_SUPPORT_HOST_USER**                          | For Wirepas support (*default=${USER}*)                                                                                               |
| **Host settings**                                 |                                                                                                                                       |
| **WM_HOST_SET_HOSTNAME**                          | Sets the hostname of the host (*default=wirepas-evk*)                                                                                 |
| **WM_HOST_SSH_ENABLE_NETWORK_LOGIN**              | Enables ssh login using plain text passwords (Raspi only) (*default=true*)                                                            |
| **WM_HOST_IPV6_DISABLE**                          | Blacklists the IPv6 module and reboots the host (*default=false*)                                                                     |
| **WM_HOST_SET_KEYBOARD**                          | Sets the host's keyboard (*default=false*)                                                                                            |
| **WM_HOST_KEYBOARD_XKBMODEL**                     | Defines the host's keyboard model (*default=pc105*)                                                                                   |
| **WM_HOST_KEYBOARD_XKBLAYOUT**                    | Defines the host's keyboard layout (*default=gb*)                                                                                     |
| **WM_HOST_KEYBOARD_XKBVARIANT**                   | Defines the host's keyboard variant (*default=unset*)                                                                                 |
| **WM_HOST_KEYBOARD_XKBOPTIONS**                   | Defines the host's keyboard options (*default=unset*)                                                                                 |
| **WM_HOST_KEYBOARD_BACKSPACE**                    | Defines the host's keyboard backspace (*default=guess*)                                                                               |
| **WM_HOST_USER_NAME**                             | The username of the host's admin user (*default=pi*)                                                                                  |
| **WM_HOST_USER_PASSWORD**                         | The password of the host's admin user (*default=unset*)                                                                               |
| **WM_HOST_USER_PPKI**                             | The public key to authorize in the ssh authorized keys (*default=unset*)                                                              |
| **WM_WIFI_DISABLE**                               | When true forces the WiFi interface to be down (*default=true*)                                                                       |
| **WM_WIFI_AP_SSID**                               | The WiFi SSID to connect to (*default=unset*)                                                                                         |
| **WM_WIFI_AP_PASSWORD**                           | The WiFi's SSID password (*default=unset*)                                                                                            |
| **WM_RPI_EXPAND_FILESYSTEM**                      | When true expands the raspi filesystem (*default=true*)                                                                               |
| **Web services integration**                      |                                                                                                                                       |
| **WM_SLACK_WEBHOOK**                              | A slack webhook where to post information about the wm-config execution (*default=unset*)                                             |
| **WM_MSTEAMS_WEBHOOK**                            | A microsoft teams webhook where to post information about the wm-config execution (*default=unset*)                                   |

<!-- table_end -->

## Accessing a wm-config gateway through the network

These steps require that you have physical access to a raspberry pi (RPi), whose hostname
is set as wm-evk.

### Logging into the RPi

Assuming your host and RPi are on the same network, you have
two options to connect remotely to the RPi:

-   using private and public key pairs (more secure)

-   using plain text logins over ssh (not recommended)

The software shipped with the Wirepas EVK allows you to connect with both
methods. The private and public method is always available but you can
enable or disable the plain text login.

*To enable the plain text logins*, insert the RPi sdcard on a host with a
sdcard reader and open the file in /boot/wirepas/custom.env. Locate and
ensure that the following key has value set to true

```shell
   WM_HOST_SSH_ENABLE_NETWORK_LOGIN="true"
```

and that you change the password in

```shell
   WM_HOST_USER_PASSWORD
```

It is also important to known what is the hostname of your device. You can
read or change hostname from the key

```shell
   WM_HOST_SET_HOSTNAME=wm-evk
```

After you insert the sdcard back on the RPi and power it on you can
connect remotely using

```shell

   ssh pi@wm-evk.local

   password: the value of WM_HOST_USER_PASSWORD

```

*To enable the logins with private and public keys* you will need to have
a private and public key pair. Generate a key pair using [ssh-keygen](https://linux.die.net/man/1/ssh-keygen).

Locate and copy the value of your *public key* to the following key in
[/boot/wirepas/custom.env][here_environment_custom].

```shell
   WM_HOST_USER_PPKI
```

After you insert the sdcard back on the RPi and power it on you can
connect remotely using

```shell
   ssh -i <path to private key> pi@wm-evk.local
```

If you opt for private key login, it is recommended that you drop the
plain text login by setting

```shell
   WM_HOST_SSH_ENABLE_NETWORK_LOGIN="false"
```

### Defining where to publish data

On a RPi, the wm-config sources the destination of the data
from */boot/wirepas/custom.env*.

Ensure that the values in the following keys are correct:

```shell
    # /boot/wirepas/custom.env
    WM_SERVICES_HOST:  broker ip or hostname
    WM_SERVICES_MQTT_PORT: broker secure port (8883 default)
    WM_SERVICES_MQTT_USER: user defined in the MQTT broker credentials
    WM_SERVICES_MQTT_PASSWORD: password defined in the MQTT broker credentials
```

If you need to change a value, remember to run wm-config after each
change to the configuration file.

Assuming the keys have the correct values, ensure that the services are
running by inspecting their status with:

```shell

   cd ~/wirepas/wm-config/lxgw

   docker-compose ps

   docker-compose logs
```

If everything is working as expected, you will see data being published from:

```shell
   2019-02-27 07:55:38,255 | [INFO] transport_service: (...)
   2019-02-27 07:55:38,305 | [DEBUG] transport_service: (...)
   2019-02-27 07:55:38,315 | [DEBUG] transport_service: (...)
```

If there is no data being sent by the transport service ensure that:

-   Your MQTT credentials are correct

-   Your MQTT broker is running

-   Your MQTT connection is properly set (unsecure vs secure)

-   Your sink is properly connected (inspect the value of docker logs wm-sink)

-   Your devices are powered on.

## Contributing

Please read contribution guidelines from [CONTRIBUTING.md][here_contributing].

## License

Licensed under the Apache License, Version 2.0. See [LICENSE][here_license] for the full license text.

[here_bin_wmconfig]: https://github.com/wirepas/wm-config/blob/master/bin/wm-config.sh

[here_bin_wmconfig_service_home]: https://github.com/wirepas/wm-config/blob/090d38ea7f35574695b48d7054b5e72e789928be/bin/wm-config.sh#L86

[here_entrypoint_settings]: https://github.com/wirepas/wm-config/blob/090d38ea7f35574695b48d7054b5e72e789928be/bin/wm-config.sh#L82

[here_environment_custom]: https://github.com/wirepas/wm-config/blob/master/environment/custom.env

[here_environment_default]: https://github.com/wirepas/wm-config/blob/master/environment/default.env

[here_modules]: https://github.com/wirepas/wm-config/tree/master/modules

[here_docs_operation]: https://github.com/wirepas/wm-config/blob/master/docs/operation.png

[here_releases]: https://github.com/wirepas/wm-config/releases

[here_contributing]: https://github.com/wirepas/wm-config/blob/master/CONTRIBUTING.md

[here_license]: https://github.com/wirepas/wm-config/blob/master/LICENSE
