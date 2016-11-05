#!/usr/bin/env bash

DIR=`dirname $0`

# Download phpMyAdmin
if [[ ! -d /srv/www/default/database-admin ]]; then
    echo "Downloading phpMyAdmin..."
    cd /srv/www/default
    wget -q -O phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/4.6.0/phpMyAdmin-4.6.0-all-languages.tar.gz"
    tar -xf phpmyadmin.tar.gz
    mv phpMyAdmin-4.6.0-all-languages database-admin
    rm phpmyadmin.tar.gz
else
    echo "PHPMyAdmin already installed."
fi
cp "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
