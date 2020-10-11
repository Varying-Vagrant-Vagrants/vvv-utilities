#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION

PHPVERSION="7.1"

apt_package_install_list=(

  # PHP
  #
  # Our base packages for php8.0. As long as php8.0-fpm and php8.0-cli are
  # installed, there is no need to install the general php8.0 package, which
  # can sometimes install apache as a requirement.
  "php${PHPVERSION}-fpm"
  "php${PHPVERSION}-cli"

  # Common and dev packages for php
  "php${PHPVERSION}-common"
  "php${PHPVERSION}-dev"

  # Extra PHP modules that we find useful
  "php${PHPVERSION}-imagick"
  "php${PHPVERSION}-memcache"
  "php${PHPVERSION}-memcached"
  php-pcov
  php-ssh2
  php-xdebug
  "php${PHPVERSION}-bcmath"
  "php${PHPVERSION}-curl"
  "php${PHPVERSION}-gd"
  "php${PHPVERSION}-intl"
  "php${PHPVERSION}-mbstring"
  "php${PHPVERSION}-mysql"
  "php${PHPVERSION}-imap"
  "php${PHPVERSION}-json"
  "php${PHPVERSION}-soap"
  "php${PHPVERSION}-xml"
  "php${PHPVERSION}-zip"
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
  cp -f "${DIR}/php7.1-upstream.conf" "/etc/nginx/upstreams/php71.conf"
  echo " * Copied ${DIR}/php7.1-upstream.conf              to /etc/nginx/upstreams/php71.conf"

  # Copy php-fpm configuration from local
  cp -f "${DIR}/php7.1-fpm.conf" "/etc/php/7.1/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/php7.1-fpm.conf                   to /etc/php/7.1/fpm/php-fpm.conf"

  cp -f "${DIR}/php7.1-www.conf" "/etc/php/7.1/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/php7.1-www.conf                   to /etc/php/7.1/fpm/pool.d/www.conf"

  cp -f "${DIR}/php7.1-custom.ini" "/etc/php/7.1/fpm/conf.d/php-custom.ini"
  echo " * Copied ${DIR}/php7.1-custom.ini                 to /etc/php/7.1/fpm/conf.d/php-custom.ini"

  cp -f "/srv/config/php-config/opcache.ini" "/etc/php/7.1/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/7.1/fpm/conf.d/opcache.ini"

  cp -f "/srv/config/php-config/xdebug.ini" "/etc/php/7.1/mods-available/xdebug.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/7.1/mods-available/xdebug.ini"

  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp -f "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.1/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/7.1/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp -f "/srv/config/php-config/mailhog.ini" "/etc/php/7.1/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/7.1/mods-available/mailhog.ini"
  fi

  echo " * Restarting php7.1-fpm service "
  service php7.1-fpm restart
}

package_install
configure

echo " * Restoring the default PHP CLI version"
update-alternatives --set php /usr/bin/php7.2
update-alternatives --set phar /usr/bin/phar7.2
update-alternatives --set phar.phar /usr/bin/phar.phar7.2
update-alternatives --set phpize /usr/bin/phpize7.2
update-alternatives --set php-config /usr/bin/php-config7.2

echo "PHP 7.1 provisioning complete"
