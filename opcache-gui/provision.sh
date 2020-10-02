#!/usr/bin/env bash
# Checkout Opcache GUI to provide a dashboard for viewing statistics

if [[ ! -d "/srv/www/default/opcache-gui" ]]; then
	echo -e " * Downloading Opcache GUI, see https://github.com/amnuts/opcache-gui"
	mkdir -p /srv/www/defaultopcache-gui
	cd /srv/www/default/opcache-gui
else
	echo -e " * Updating Opcache GUI"
	cd /srv/www/default/opcache-gui
fi

composer require amnuts/opcache-gui

ln -s ./vendor/amnuts/opcache-gui/index.php ./index.php
