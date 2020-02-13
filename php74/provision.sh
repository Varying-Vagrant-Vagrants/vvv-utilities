#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION

apt_package_install_list=(

  # PHP7.4
  #
  # Our base packages for php7.4. As long as php7.4-fpm and php7.4-cli are
  # installed, there is no need to install the general php7.4 package, which
  # can sometimes install apache as a requirement.
  php7.4-fpm
  php7.4-cli

  # Common and dev packages for php
  php7.4-common
  php7.4-dev

  # Extra PHP modules that we find useful
  php-imagick
  php-memcache
  php-memcached
  php-pcov
  php-ssh2
  php-xdebug
  php7.4-bcmath
  php7.4-curl
  php7.4-gd
  php7.4-mbstring
  php7.4-mysql
  php7.4-imap
  php7.4-json
  php7.4-soap
  php7.4-xml
  php7.4-zip
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
  cp -f "${DIR}/php7.4-upstream.conf" "/etc/nginx/upstreams/php74.conf"

  # Copy php-fpm configuration from local
  cp -f "${DIR}/php7.4-fpm.conf" "/etc/php/7.4/fpm/php-fpm.conf"
  cp -f "${DIR}/php7.4-www.conf" "/etc/php/7.4/fpm/pool.d/www.conf"
  cp -f "${DIR}/php7.4-custom.ini" "/etc/php/7.4/fpm/conf.d/php-custom.ini"
  cp -f "/srv/config/php-config/opcache.ini" "/etc/php/7.4/fpm/conf.d/opcache.ini"
  cp -f "/srv/config/php-config/xdebug.ini" "/etc/php/7.4/mods-available/xdebug.ini"
  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp -f "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.4/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/7.4/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp -f "/srv/config/php-config/mailhog.ini" "/etc/php/7.4/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/7.4/mods-available/mailhog.ini"
  fi

  echo " * Copied ${DIR}/php7.4-fpm.conf                   to /etc/php/7.4/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/php7.4-www.conf                   to /etc/php/7.4/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/php7.4-custom.ini                 to /etc/php/7.4/fpm/conf.d/php-custom.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/7.4/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/7.4/mods-available/xdebug.ini"

  service php7.4-fpm restart
}

package_install
configure

# Change the CLI PHP back to 7.2
update-alternatives --set php /usr/bin/php7.2
update-alternatives --set phar /usr/bin/phar7.2
update-alternatives --set phar.phar /usr/bin/phar.phar7.2
update-alternatives --set phpize /usr/bin/phpize7.2
update-alternatives --set php-config /usr/bin/php-config7.2

echo " * PHP 7.4 installed"
