# WM Config

<!-- MarkdownTOC -->

- [Introduction](#introduction)
- [Customizing wm-config - creating a custom.env file](#customizing-wm-config---creating-a-customenv-file)
- [Installation](#installation)
  - [Installing from github](#installing-from-github)
  - [Creating and installing from an archive](#creating-and-installing-from-an-archive)
- [Inspecting the services status](#inspecting-the-services-status)
- [Guides](#guides)
- [Contributing](#contributing)
- [License](#license)

<!-- /MarkdownTOC -->

## Introduction

The Wirepas Host Configurator (wm-config)
is a [bash utility][here_bin_wmconfig]
which effortlessly configures your host computer
with the Wirepas gateway software.

WM-CONFIG relies on the Docker engine to setup the gateway services.
**Figure 1** provides a quick glance of the utility's place in the
host environment and a short overview of its operation.

![runtime operation of wm-config][here_docs_operation]

**Figure 1:** provides an overview of the steps taken by wm-config.

After its installation the utility is meant to be summoned
anywhere by typing:

```bash
   wm-config [--help]
```

As depicted in **Figure 1**, wm-config starts by sourcing
the bash modules (see [/modules][here_modules]),
evaluating the [custom][here_environment_custom]
and [default][here_environment_default]
environment files.

Once the evaluation of the files is done, wm-config will
install any dependencies in your host, generate the
composition files and start the gateway services.

Under a Raspberry Pi (RPi), wm-config will be able to change
several host settings, including hostname, ssh authorized
keys, WiFi AP client settings, among others.

For non-RPi hosts, wm-config is restricted on its operations,
which consist of setting up symlinks for the tty ports and
installing system dependencies.

<!-- auto_start -->
## Customizing wm-config - creating a custom.env file

The wm-config utility is highly configurable through a single environment file. The
environment file is sourced based on the path defined with
[**WM_CFG_SETTINGS_CUSTOM**][here_settings_custom].

The custom.env file overrides the default values present in the default settings file
distributed with a given version of the framework. You should never change the default values unless you
know what you are doing.

The environment keys that define the custom file location and store the framework version are:

-   **WM_CFG_VERSION** : Current WM-CONFIG version in use

-   **WM_CFG_SETTINGS_CUSTOM**  : Path to the custom settings file

Besides knowing where the custom settings are loaded from, it is very important for you to
understand how you can control where to publish data and which version of the gateway you are running.

The keys that allow you to change such behaviour are the following ones:

| **Key**                         | **Description and default value**                                                                          |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **WM_GW_IMAGE**                 | The name of the WM Gateway Docker image to pull  (*default=wirepas/gateway*)                                 |
| **WM_GW_VERSION**               | The build or docker tag to use (*default=latest*)                                                 |
| _MQTT hostname and credentials_ |                                                                                                            |
| **WM_SERVICES_MQTT_HOSTNAME**              | A host where to push the gateway data, eg, MQTT broker hostname or ip  (*default=host.extwirepas.com*)        |
| **WM_SERVICES_MQTT_USER**         | The MQTT username (*default=mqttuser*)                                                        |
| **WM_SERVICES_MQTT_PASSWORD**     | The MQTT's username password corresponding (*default=uiaidujfk1897fyeu023849sdh?(*)                           |
| **WM_SERVICES_MQTT_PORT**         | Defines the MQTT port to use (unsecure 1883, secure 8883) (*default=8883*)                |
| **WM_SERVICES_ALLOW_UNSECURE**    | Must be set to true to allow unsecure connections, eg, to port 1883 (*default=unset*) |

When using a Raspberry Pi, it is useful to set a unique hostname to allow easy ssh through the advertised avahi name.
Besides that, you can also enable and disable password based access as well as private public key based access.

Here are the keys for such purpose:

| **Key**                            | **Description and default value**                                                         |
| ---------------------------------- | ----------------------------------------------------------------------------------------- |
| **WM_HOST_HOSTNAME**             | Sets the hostname of the host (##WM_HOST_SET_HOSTNAME_DEFAULT)                            |
| **WM_HOST_USER_PPKI**                | The public key to authorize in the ssh authorized keys (*default=unset*)      |
| **WM_HOST_SSH_ENABLE_NETWORK_LOGIN** | Enables ssh login using plain text passwords (*default=true*) |

Please refer to [environment/custom.env][here_environment_custom] for an example on how to define a custom.env file.

A full list of keys is available from [docs/settings.md][here_settings_list].

[here_settings_custom]: https://github.com/wirepas/wm-config/blob/ebec460eddd5f8f9173f07b8dd698c56a12b80a2/bin/wm-config.sh#L84-L95

[here_settings_list]: https://github.com/wirepas/wm-config/blob/master/docs/settings.md
<!-- auto_end -->

## Installation

You can chose to install directly from github or from an archive.

### Installing from github

Clone this repository, checkout [a release tag][here_releases] and run:

```bash
   ./setup.sh --skip-call
```

The repository files will be copied under
[WM_CFG_INSTALL_PATH][here_bin_wmconfig_service_home].

Copy your custom.env file to the path specified in
[WM_CFG_SETTINGS_CUSTOM][here_entrypoint_settings]
and call the utility with:

```bash
   wm-config
```

### Creating and installing from an archive

An archive bundle is useful to share across multiple hosts
without having to install and clone the repository N times.

To build an archive, clone the repository on a machine
with bash and run the following script:

```bash
   ./setup.sh --pack
```

An archive will be created under ./deliverable/wm-config.tar.gz_.

Copy the following files to the host where you want to perform
the installation:

-   ./deliverable/wm-config.tar.gz
-   setup.sh
-   custom.env

Once the copy is complete, login in the device and call
setup.sh. The script will extract the files, copy them
to [WM_CFG_INSTALL_PATH][here_bin_wmconfig_service_home] and
call wm-config.

As an example, let's assume your user is _someuser_
and the machine where you want to install wm-config
is known in your network with IP 192.168.1.10.

To copy the files you would type the following commands:

```bash
   scp ./deliverable/wm-config.tar.gz someuser@192.168.1.10:
   scp ./setup.sh someuser@192.168.1.10:
   scp ~/custom.env someuser@192.168.1.10:

   ssh someuser@192.168.1.10
   ./setup.sh
```

To successfully run the commands in your environment you would
need to set the correct user name and the correct IP or host name
for your target machine.

## Inspecting the services status

To inspect the status of the gateway services type:

```bash
   wm-config --status
```

The utility will show you the latest logs from the sink and
transport service.

Alternatively, you can view the logs yourself through the docker
engine or docker compose.

With plain docker commands, type:

```bash
   docker ps : to view the status of the services

   docker logs <container name>
```

With docker compose either change
directory to [WM_CFG_INSTALL_PATH][here_bin_wmconfig_service_home]
or provide the path to the compose file with the *-f* switch :

```bash
   docker-compose [ -f $WM_CFG_INSTALL_PATH/lxgw/docker-compose.yml ] ps

   docker-compose [ -f $WM_CFG_INSTALL_PATH/lxgw/docker-compose.yml ] logs
```

If you wish to stop the services type:

```bash
   wm-config --state stop
```

To resume operation type:

```bash
   wm-config --state start
```

For other arguments, please review the help output with:

```bash
   wm-config --help
```

## Guides

[How to prepare a RPi with wm-config][here_guide_rpi_setup]

## Contributing

Please read contribution guidelines from [CONTRIBUTING.md][here_contributing].

## License

Licensed under the Apache License, Version 2.0.
See [LICENSE][here_license] for the full license text.

[here_bin_wmconfig]: https://github.com/wirepas/wm-config/blob/master/bin/wm-config.sh

[here_bin_wmconfig_service_home]: https://github.com/wirepas/wm-config/blob/090d38ea7f35574695b48d7054b5e72e789928be/bin/wm-config.sh#L86

[here_entrypoint_settings]: https://github.com/wirepas/wm-config/blob/090d38ea7f35574695b48d7054b5e72e789928be/bin/wm-config.sh#L82

[here_environment_custom]: https://github.com/wirepas/wm-config/blob/master/environment/custom.env

[here_environment_default]: https://github.com/wirepas/wm-config/blob/master/environment/default.env

[here_modules]: https://github.com/wirepas/wm-config/tree/master/modules

[here_docs_operation]: ./docs/img/overview.png

[here_releases]: https://github.com/wirepas/wm-config/releases

[here_contributing]: https://github.com/wirepas/wm-config/blob/master/CONTRIBUTING.md

[here_license]: https://github.com/wirepas/wm-config/blob/master/LICENSE

[here_guide_rpi_setup]: ./docs/guide_rpi.md
