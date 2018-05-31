#!/usr/bin/env bash

DIR=`dirname $0`

# phpMyAdmin
echo -e "Installing/Updating phpMyAdmin..."
cd "${DIR}"
composer update --no-autoloader

cp "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
