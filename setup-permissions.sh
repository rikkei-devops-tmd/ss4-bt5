#!/bin/bash
set -e

sudo mkdir -p /opt/my-app/html /opt/my-app/logs
sudo chown -R devops:www-data /opt/my-app
sudo chmod 755 /opt/my-app /opt/my-app/html
sudo chmod 775 /opt/my-app/logs
sudo find /opt/my-app/html -type f -exec chmod 644 {} +
