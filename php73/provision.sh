#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION
apt_package_install_list=(

  # PHP7.3
  #
  # Our base packages for php7.3. As long as php7.3-fpm and php7.3-cli are
  # installed, there is no need to install the general php7.3 package, which
  # can sometimes install apache as a requirement.
  php7.3-fpm
  php7.3-cli

  # Common and dev packages for php
  php7.3-common
  php7.3-dev

  # Extra PHP modules that we find useful
  php-imagick
  php-memcache
  php-memcached
  php-pcov
  php-ssh2
  php-xdebug
  php7.3-bcmath
  php7.3-curl
  php7.3-gd
  php7.3-mbstring
  php7.3-mysql
  php7.3-imap
  php7.3-json
  php7.3-soap
  php7.3-xml
  php7.3-zip
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
  cp -f "${DIR}/php7.3-upstream.conf" "/etc/nginx/upstreams/php73.conf"

  # Copy php-fpm configuration from local
  cp -f "${DIR}/php7.3-fpm.conf" "/etc/php/7.3/fpm/php-fpm.conf"
  cp -f "${DIR}/php7.3-www.conf" "/etc/php/7.3/fpm/pool.d/www.conf"
  cp -f "${DIR}/php7.3-custom.ini" "/etc/php/7.3/fpm/conf.d/php-custom.ini"
  cp -f "/srv/config/php-config/opcache.ini" "/etc/php/7.3/fpm/conf.d/opcache.ini"
  cp -f "/srv/config/php-config/xdebug.ini" "/etc/php/7.3/mods-available/xdebug.ini"
  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.3/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/7.3/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp -f "/srv/config/php-config/mailhog.ini" "/etc/php/7.3/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/7.3/mods-available/mailhog.ini"
  fi

  echo " * Copied ${DIR}/php7.3-fpm.conf                   to /etc/php/7.3/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/php7.3-www.conf                   to /etc/php/7.3/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/php7.3-custom.ini                 to /etc/php/7.3/fpm/conf.d/php-custom.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/7.3/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/7.3/mods-available/xdebug.ini"

  service php7.3-fpm restart
}

package_install
configure

# Change the CLI PHP back to 7.2
update-alternatives --set php /usr/bin/php7.2
update-alternatives --set phar /usr/bin/phar7.2
update-alternatives --set phar.phar /usr/bin/phar.phar7.2
update-alternatives --set phpize /usr/bin/phpize7.2
update-alternatives --set php-config /usr/bin/php-config7.2

echo " * PHP 7.3 installed"
