#!/usr/bin/env bash
# Checkout Opcache Status to provide a dashboard for viewing statistics
# about PHP's built in opcache.

echo -e " ! Opcache Status is abandoned, please switch to the new VVV utility opcache-gui in config.yml"

if [[ ! -d "/srv/www/default/opcache-status" ]]; then
	echo -e " * Downloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
	cd /srv/www/default
	noroot git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
else
	echo -e " * Updating Opcache Status"
	cd /srv/www/default/opcache-status
	noroot git pull --rebase origin master
fi
