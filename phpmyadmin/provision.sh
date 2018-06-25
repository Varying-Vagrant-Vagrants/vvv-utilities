#!/usr/bin/env bash

DIR=`dirname $0`

# Download phpMyAdmin
if [[ ! -f /srv/www/default/database-admin/RELEASE-DATE-4.8.1 ]]; then
    echo "Removing older phpMyAdmin install"
    rm -rf /srv/www/default/database-admin/*
    echo "Downloading phpMyAdmin 4.8.1"
    cd /srv/www/default
    wget -q -O phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/4.8.1/phpMyAdmin-4.8.1-all-languages.tar.gz"
    tar -xf phpmyadmin.tar.gz
    mv phpMyAdmin-4.8.1-all-languages database-admin
    rm phpmyadmin.tar.gz
else
    echo "PHPMyAdmin already installed."
fi
cp "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
