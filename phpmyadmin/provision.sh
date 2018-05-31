#!/usr/bin/env bash

DIR=`dirname $0`

# phpMyAdmin
mkdir -p /srv/www/default/database-admin
cd "/srv/www/default/database-admin"
if composer status; then
  echo "Updating PHPMyAdmin"
  composer update --no-autoloader
else
  echo "Installing PHPMyAdmin"
  # clean up any old installs from pre-composer setup
  rm -rf /srv/www/default/database-admin/
  # Install using the phpmyadmin composer repo so that languages are bundled
  composer create-project phpmyadmin/phpmyadmin --repository-url=https://www.phpmyadmin.net/packages.json --no-dev .
end

cd $DIR

echo "Copying over PHPMyAdmin config file"

cp "${DIR}/config.inc.php" "/srv/www/default/database-admin/"
