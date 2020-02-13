#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION
apt_package_install_list=(

  # PHP5.6
  #
  # Our base packages for php5.6. As long as php5.6-fpm and php5.6-cli are
  # installed, there is no need to install the general php5.6 package, which
  # can sometimes install apache as a requirement.
  php5.6-fpm
  php5.6-cli

  # Common and dev packages for php
  php5.6-common
  php5.6-dev

  # Extra PHP modules that we find useful
  php-imagick
  php-memcache
  php-memcached
  php-pcov
  php-ssh2
  php-xdebug
  php5.6-bcmath
  php5.6-curl
  php5.6-gd
  php5.6-mbstring
  php5.6-mcrypt
  php5.6-mysql
  php5.6-imap
  php5.6-json
  php5.6-soap
  php5.6-xml
  php5.6-zip
)

### FUNCTIONS
package_install() {
  # Update all of the package references before installing anything
  echo " * Running apt-get update..."
  apt-get -y update

  # Install required packages
  echo " * Installing apt-get packages..."
  if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${apt_package_install_list[@]}; then
    echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
    apt-get clean
    return 1
  fi

  # Remove unnecessary packages
  echo " * Removing unnecessary packages..."
  apt-get autoremove -y

  # Clean up apt caches
  echo " * Cleaning apt caches..."
  apt-get clean

  return 0
}

configure() {
  # Copy nginx configuration from local
  cp -f "${DIR}/php5.6-upstream.conf" "/etc/nginx/upstreams/php56.conf"
  echo " * Copied ${DIR}/php5.6-upstream.conf              to /etc/nginx/upstreams/php56.conf"

g
  # Copy php-fpm configuration from local
  cp -f "${DIR}/php5.6-fpm.conf" "/etc/php/5.6/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/php5.6-fpm.conf                   to /etc/php/5.6/fpm/php-fpm.conf"

  cp -f "${DIR}/php5.6-www.conf" "/etc/php/5.6/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/php5.6-www.conf                   to /etc/php/5.6/fpm/pool.d/www.conf"

  cp -f "${DIR}/php5.6-custom.ini" "/etc/php/5.6/fpm/conf.d/php-custom.ini"
  echo " * Copied ${DIR}/php5.6-custom.ini                 to /etc/php/5.6/fpm/conf.d/php-custom.ini"

  cp -f "/srv/config/php-config/opcache.ini" "/etc/php/5.6/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/5.6/fpm/conf.d/opcache.ini"

  cp -f "/srv/config/php-config/xdebug.ini" "/etc/php/5.6/mods-available/xdebug.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/5.6/mods-available/xdebug.ini"

  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp -f "/srv/config/php-config/mailcatcher.ini" "/etc/php/5.6/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/5.6/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp "/srv/config/php-config/mailhog.ini" "/etc/php/5.6/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/5.6/mods-available/mailhog.ini"
  fi

  echo " * Restarting php5.6-fpm service"
  service php5.6-fpm restart
}

package_install
configure

echo " * Restoring the default PHP CLI version"
update-alternatives --set php /usr/bin/php7.2
update-alternatives --set phar /usr/bin/phar7.2
update-alternatives --set phar.phar /usr/bin/phar.phar7.2
update-alternatives --set phpize /usr/bin/phpize7.2
update-alternatives --set php-config /usr/bin/php-config7.2

echo " * PHP 5.6 provisioning complete"
