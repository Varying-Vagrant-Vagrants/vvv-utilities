#!/usr/bin/env bash
# Provision WP-CLI develop and do an alias to the original wpcli

cd "/srv/www/"

DB_NAME='wp_cli_test'

echo "Downloading a developer version of WP-CLI"

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp_cli_test@localhost IDENTIFIED BY 'password1';"
echo -e "\n DB operations done.\n\n"

sudo apt install -y jq

git clone https://github.com/wp-cli/wp-cli-dev
cd wp-cli-dev
composer install --no-dev

echo "Creating the symlink as wp-dev"
ln -s /srv/www/wp-cli-dev/vendor/bin/wp /usr/local/bin/wp-dev
