FROM bash:5.0

ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-"1.1.3"}

WORKDIR /home/wirepas/settings
COPY . .
RUN chown -R 1000:1000 .

RUN cp ./bin/wmconfig-settings-updater.sh /usr/local/bin/wmconfig-settings-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" /usr/local/bin/wmconfig-settings-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" ./bin/wm-config.sh

RUN chmod +x /usr/local/bin/wmconfig-settings-updater
CMD wmconfig-settings-updater

