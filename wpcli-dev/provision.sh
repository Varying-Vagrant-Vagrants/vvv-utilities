#!/usr/bin/env bash
# Provision WP-CLI develop and do an alias to the original wpcli
export DEBIAN_FRONTEND=noninteractive

cd "/srv/www/"

noroot() {
  sudo -EH -u "vagrant" "$@";
}

DB_NAME='wp_cli_test'

echo " * Provisioning WP-CLI-Dev"

# Make a database, if we don't already have one
echo -e " * Creating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp_cli_test@localhost IDENTIFIED BY 'password1';"
echo -e " * DB operations done."

echo " * Installing jq package"
if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken jq; then
  echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
  apt-get clean
  return 1
fi

if [[ ! -d /srv/www/wp-cli-dev/.git ]]; then
  echo " * Downloading official WP-CLI-Dev environment"
  noroot git clone https://github.com/wp-cli/wp-cli-dev
else
  echo "* Updating official WP-CLI-Dev environment"
  ( cd /srv/www/wp-cli-dev/ && noroot git pull -q && noroot git checkout -q )
fi

cd /srv/www/wp-cli-dev
echo " * Running composer install"
noroot composer install --no-dev

echo " * Creating the symlink as wp-dev"
ln -sf /srv/www/wp-cli-dev/vendor/bin/wp /usr/local/bin/wp-dev

echo " * WP-CLI Dev provisioned"
