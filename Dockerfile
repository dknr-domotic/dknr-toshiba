
# Use fix Node-red docker release
FROM nodered/node-red:5.0

# Switch to root user
USER root

# Set environment variables
ENV DKNR_USERNAME=admin \
      DKNR_PASSWORD=admin \
      DKNR_SECRET=dktoshiba \
      DKNR_REPOSITORY=https://github.com/dknr-domotic/dknr-toshiba \
      NODE_RED_ENABLE_PROJECTS=true \
      TZ=Europe/Paris

# Image label
LABEL org.opencontainers.image.authors="Jean-Christian Paul Denis" \
      org.opencontainers.image.source="https://github.com/dknr-domotic/dknr-toshiba" \
      org.opencontainers.image.title="DKNR Toshiba" \
      org.opencontainers.image.description="Toshiba air conditioners (Toshiba Home AC Control cloud) to MQTT with web UI" \
      org.opencontainers.image.licenses="AGPL-3.0"

# Set system timezone
RUN echo "$TZ" > /etc/timezone

# Prepare Node-Red structure
RUN mkdir -p /data/projects/dknr-toshiba

# Clone repository
RUN git clone ${DKNR_REPOSITORY} /data/projects/dknr-toshiba

# Fix ownership
RUN chown -R node-red:node-red /data

# Switch to node-red user
USER node-red

# Set working diretory for container starting script
WORKDIR /data

# Add container starting script
ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
