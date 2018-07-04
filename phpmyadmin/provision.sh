#!/usr/bin/env bash

DIR=`dirname $0`

echo "Checking phpMyAdmin"

mkdir -p /srv/www/default/database-admin

# Download phpMyAdmin
if [[ ! -f /srv/www/default/database-admin/RELEASE-DATE-4.8.1 ]]; then
    echo "Removing older phpMyAdmin install from /srv/www/default/database-admin"
    rm -rf /srv/www/default/database-admin/*
    echo "Downloading phpMyAdmin 4.8.1"
    cd /tmp
    wget -q -O phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/4.8.1/phpMyAdmin-4.8.1-all-languages.tar.gz"
    echo "Extracting phpMyAdmin 4.8.1 into /tmp"
    tar -xf phpmyadmin.tar.gz
    echo "Copying phpMyAdmin into place"
    cp -rf /tmp/phpMyAdmin-4.8.1-all-languages/* /srv/www/default/database-admin/*
    echo "Cleaning up after phpMyAdmin"
    rm -rf /tmp/phpMyAdmin-4.8.1-all-languages
    rm -f /tmp/phpmyadmin.tar.gz
    echo "phpMyAdmin setup complete"
else
    echo "PHPMyAdmin already installed."
fi
cp "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
