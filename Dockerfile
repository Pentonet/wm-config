FROM alpine as wm-settings

ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-"2.0.0"}

WORKDIR /home/wirepas/settings
COPY . .
RUN chown -R 1000:1000 .

RUN cp ./bin/wmconfig-settings-updater.sh /usr/local/bin/wmconfig-settings-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" /usr/local/bin/wmconfig-settings-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" ./bin/wm-config.sh

RUN chmod +x /usr/local/bin/wmconfig-settings-updater
CMD wmconfig-settings-updater


FROM balenalib/raspberrypi3-alpine as wm-settings-rpi

RUN [ "cross-build-start" ]

ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-"2.0.0"}

WORKDIR /home/wirepas/settings
COPY . .
RUN chown -R 1000:1000 .

RUN cp ./bin/wmconfig-settings-updater.sh /usr/local/bin/wmconfig-settings-updater
RUN sed -i "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" /usr/local/bin/wmconfig-settings-updater
RUN sed -i "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" ./bin/wm-config.sh

RUN chmod +x /usr/local/bin/wmconfig-settings-updater
CMD wmconfig-settings-updater

RUN [ "cross-build-end" ]

