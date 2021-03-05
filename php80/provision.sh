#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION
DEFAULTPHP=$(php -r "echo substr(phpversion(),0,3);")
PHPVERSION="8.0"

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
  "php${PHPVERSION}-pcov"
  "php${PHPVERSION}-ssh2"
  "php${PHPVERSION}-xdebug"
  "php${PHPVERSION}-bcmath"
  "php${PHPVERSION}-curl"
  "php${PHPVERSION}-gd"
  "php${PHPVERSION}-intl"
  "php${PHPVERSION}-mbstring"
  "php${PHPVERSION}-mysql"
  "php${PHPVERSION}-imap"
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
  cp -f "${DIR}/upstream.conf" "/etc/nginx/upstreams/php80.conf"
  echo " * Copied ${DIR}/upstream.conf              to /etc/nginx/upstreams/php80.conf"

  # Copy php-fpm configuration from local
  cp -f "${DIR}/fpm.conf" "/etc/php/${PHPVERSION}/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/fpm.conf                   to /etc/php/${PHPVERSION}/fpm/php-fpm.conf"

  cp -f "${DIR}/www.conf" "/etc/php/${PHPVERSION}/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/www.conf                   to /etc/php/${PHPVERSION}/fpm/pool.d/www.conf"

  cp -f "${DIR}/php-custom.ini" "/etc/php/${PHPVERSION}/fpm/conf.d/php-custom.ini"
  echo " * Copied ${DIR}/php-custom.ini                 to /etc/php/${PHPVERSION}/fpm/conf.d/php-custom.ini"

  cp -f "/srv/config/php-config/opcache.ini" "/etc/php/${PHPVERSION}/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/${PHPVERSION}/fpm/conf.d/opcache.ini"

  cp -f "/srv/config/php-config/xdebug.ini" "/etc/php/${PHPVERSION}/mods-available/xdebug.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/${PHPVERSION}/mods-available/xdebug.ini"

  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp -f "/srv/config/php-config/mailcatcher.ini" "/etc/php/${PHPVERSION}/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/${PHPVERSION}/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp -f "/srv/config/php-config/mailhog.ini" "/etc/php/${PHPVERSION}/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/${PHPVERSION}/mods-available/mailhog.ini"
  fi

  echo " * Restarting php${PHPVERSION}-fpm service "
  service "php${PHPVERSION}-fpm" restart
}

package_install
configure

echo " * Restoring the default PHP CLI version ( ${DEFAULTPHP} )"
update-alternatives --set php "/usr/bin/php${DEFAULTPHP}"
update-alternatives --set phar "/usr/bin/phar${DEFAULTPHP}"
update-alternatives --set phar.phar "/usr/bin/phar.phar${DEFAULTPHP}"
update-alternatives --set phpize "/usr/bin/phpize${DEFAULTPHP}"
update-alternatives --set php-config "/usr/bin/php-config${DEFAULTPHP}"

echo " * PHP ${PHPVERSION} provisioning complete"
