FROM bash:5.0

ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-"2.0.0"}
ENV WM_CFG_UPDATER_WORKDIR="/wm-config/updater"

WORKDIR /wm-config/updater
COPY . .
RUN cp ./bin/wm-config-updater.sh /usr/local/bin/wm-config-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" /usr/local/bin/wm-config-updater
RUN sed -i.bak "s/#FILLVERSION/$(date -u) - ${BUILD_VERSION}/g" ./bin/wm-config.sh

RUN chmod +x /usr/local/bin/wm-config-updater
CMD wm-config-updater

