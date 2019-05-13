#!/usr/bin/env bash
# Tideways by site runner
DIR=$(dirname "$0")

echo "Tideways-by-site provisioner started"

sudo apt install php-yaml -y
php "${DIR}/provision.php" "${VVV_CONFIG}"

echo "Tideways-by-site provisioner runned"
