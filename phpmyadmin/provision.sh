#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo " * Checking for phpMyAdmin v4.9.1"

# Download phpMyAdmin
if [[ ! -f /srv/www/default/database-admin/RELEASE-DATE-4.9.1 ]]; then
    echo " * Removing older phpMyAdmin install from /srv/www/default/database-admin"
    rm -rf /srv/www/default/database-admin/*
    echo " * Downloading phpMyAdmin 4.9.1"
    cd /tmp
    wget -q -O phpmyadmin.zip "https://files.phpmyadmin.net/phpMyAdmin/4.9.1/phpMyAdmin-4.9.1-all-languages.zip"
    echo " * Extracting phpMyAdmin v4.9.1 into /tmp"
    unzip phpmyadmin.zip
    echo " * Copying phpMyAdmin into place"
    mkdir -p /srv/www/default/database-admin
    cp -rf /tmp/phpMyAdmin-4.9.1-all-languages/* /srv/www/default/database-admin/
    echo " * Cleaning up after phpMyAdmin"
    rm -rf /tmp/phpMyAdmin*
    rm -f /tmp/phpmyadmin.zip
    echo " * phpMyAdmin setup complete"
else
    echo " * PHPMyAdmin v4.9.1 already installed."
fi
cp -f "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
