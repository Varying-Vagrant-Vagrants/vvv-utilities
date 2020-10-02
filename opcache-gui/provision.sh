#!/usr/bin/env bash
# Checkout Opcache GUI to provide a dashboard for viewing statistics

if [[ ! -d "/srv/www/default/opcache-gui" ]]; then
	echo -e " * Downloading Opcache GUI, see https://github.com/amnuts/opcache-gui"
	noroot mkdir -p /srv/www/default/opcache-gui
else
	echo -e " * Updating Opcache GUI"
fi

cd /srv/www/default/opcache-gui
noroot composer require amnuts/opcache-gui

noroot ln -s ./vendor/amnuts/opcache-gui/index.php ./index.php
