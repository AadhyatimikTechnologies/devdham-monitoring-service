#!/bin/sh

echo "Starting DevDham Grafana monitoring service..."
echo "Connecting to Cloud SQL via Cloud Run connector..."

# Cloud Run automatically handles Cloud SQL connections
# No need for Cloud SQL proxy in the container
exec /run.sh