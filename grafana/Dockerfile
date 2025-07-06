# Use official Grafana image as base
FROM grafana/grafana:10.2.0

# Switch to root user to install dependencies
USER root

# Install Cloud SQL proxy using Alpine package manager
RUN apk add --no-cache wget curl && \
    wget -q https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/local/bin/cloud_sql_proxy && \
    chmod +x /usr/local/bin/cloud_sql_proxy

# Copy Grafana configuration
COPY grafana.ini /etc/grafana/grafana.ini

# Copy provisioning configurations
COPY provisioning/ /etc/grafana/provisioning/

# Create startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Create directories for plugins and dashboards
RUN mkdir -p /var/lib/grafana/plugins && \
    mkdir -p /etc/grafana/provisioning/dashboards && \
    mkdir -p /etc/grafana/provisioning/datasources && \
    mkdir -p /etc/grafana/provisioning/notifiers

# Install Google Cloud Monitoring datasource plugin
RUN grafana-cli plugins install grafana-googlesheets-datasource || true
RUN grafana-cli plugins install grafana-clock-panel || true

# Switch back to grafana user
USER grafana

# Expose Grafana port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Use custom startup script
ENTRYPOINT ["/start.sh"]