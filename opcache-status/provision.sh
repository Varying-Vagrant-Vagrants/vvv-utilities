#!/usr/bin/env bash
# Checkout Opcache Status to provide a dashboard for viewing statistics
# about PHP's built in opcache.
if [[ ! -d "/srv/www/default/opcache-status" ]]; then
	echo -e "\nDownloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
	cd /srv/www/default
	git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
else
	echo -e "\nUpdating Opcache Status"
	cd /srv/www/default/opcache-status
	git pull --rebase origin master
fi
