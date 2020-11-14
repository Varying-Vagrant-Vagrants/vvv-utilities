#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PHPMYADMINVERSION="4.9.7"
echo " * Checking for phpMyAdmin v${PHPMYADMINVERSION}"

# Download phpMyAdmin
if [[ ! -f "/srv/www/default/database-admin/RELEASE-DATE-${PHPMYADMINVERSION}" ]]; then
    echo " * Removing older phpMyAdmin install from /srv/www/default/database-admin"
    rm -rf /srv/www/default/database-admin/*
    echo " * Downloading phpMyAdmin v${PHPMYADMINVERSION}"
    cd /tmp
    wget -q -O phpmyadmin.zip "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMINVERSION}/phpMyAdmin-${PHPMYADMINVERSION}-all-languages.zip"
    echo " * Extracting phpMyAdmin v${PHPMYADMINVERSION} into /tmp"
    unzip phpmyadmin.zip
    rm -f /tmp/phpmyadmin.zip
    mkdir -p /srv/www/default/database-admin
    echo " * Clearing out old phpMyAdmin"
    rm -rf /srv/www/default/database-admin/*
    echo " * Copying phpMyAdmin v${PHPMYADMINVERSION} into place"
    cp -rf /tmp/phpMyAdmin-${PHPMYADMINVERSION}-all-languages/* /srv/www/default/database-admin/
    echo " * Cleaning up install files"
    rm -rf /tmp/phpMyAdmin*
    echo " * phpMyAdmin v${PHPMYADMINVERSION} installation complete"
else
    echo " * PHPMyAdmin v${PHPMYADMINVERSION} already installed."
fi
echo " * Overwriting config file with the latest version"
cp -f "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
