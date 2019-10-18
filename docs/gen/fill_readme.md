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

| **Key**                         | **Description and default value**                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| ##WM_GW_IMAGE                   | The name of the WM Gateway Docker image to pull  (##WM_GW_IMAGE_DEFAULT)                                     |
| ##WM_GW_VERSION                 | The build or docker tag to use (##WM_GW_VERSION_DEFAULT)                                                     |
| *MQTT hostname and credentials* |                                                                                                              |
| ##WM_SERVICES_MQTT_HOSTNAME     | A host where to push the gateway data, eg, MQTT broker hostname or ip  (##WM_SERVICES_MQTT_HOSTNAME_DEFAULT) |
| ##WM_SERVICES_MQTT_USERNAME     | The MQTT username (##WM_SERVICES_MQTT_USERNAME_DEFAULT)                                                      |
| ##WM_SERVICES_MQTT_PASSWORD     | The MQTT's username password corresponding (##WM_SERVICES_MQTT_PASSWORD_DEFAULT)                             |
| ##WM_SERVICES_MQTT_PORT         | Defines the MQTT port to use (unsecure 1883, secure 8883) (##WM_SERVICES_MQTT_PORT_DEFAULT)                  |
| ##WM_SERVICES_ALLOW_UNSECURE    | Must be set to true to allow unsecure connections, eg, to port 1883 (##WM_SERVICES_ALLOW_UNSECURE_DEFAULT)   |

When using a Raspberry Pi, it is useful to set a unique hostname to allow easy ssh through the advertised avahi name.
Besides that, you can also enable and disable password based access as well as private public key based access.

Here are the keys for such purpose:

| **Key**                             | **Description and default value**                                                          |
| ----------------------------------- | ------------------------------------------------------------------------------------------ |
| ##WM_HOST_HOSTNAME                  | Sets the hostname of the host (##WM_HOST_SET_HOSTNAME_DEFAULT)                             |
| ##WM_HOST_USER_PPKI                 | The public key to authorize in the ssh authorized keys (##WM_HOST_USER_PPKI_DEFAULT)       |
| ##WM_HOST_SSH_ENABLE_PASSWORD_LOGIN | Enables ssh login using plain text passwords (##WM_HOST_SSH_ENABLE_PASSWORD_LOGIN_DEFAULT) |

Please refer to [environment/custom.env][here_environment_custom] for an example on how to define a custom.env file.

A full list of keys is available from [docs/settings.md][here_settings_list].

[here_settings_custom]: https://github.com/wirepas/wm-config/blob/ebec460eddd5f8f9173f07b8dd698c56a12b80a2/bin/wm-config.sh#L84-L95

[here_settings_list]: https://github.com/wirepas/wm-config/blob/master/docs/settings.md
