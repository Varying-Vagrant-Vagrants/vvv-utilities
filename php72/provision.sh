#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# PACKAGE INSTALLATION
apt_package_install_list=(

  # PHP7.2
  #
  # Our base packages for php7.2. As long as php7.2-fpm and php7.2-cli are
  # installed, there is no need to install the general php7.2 package, which
  # can sometimes install apache as a requirement.
  php7.2-fpm
  php7.2-cli

  # Common and dev packages for php
  php7.2-common
  php7.2-dev

  # Extra PHP modules that we find useful
  php-imagick
  php-memcache
  php-memcached
  php-ssh2
  php-xdebug
  php7.2-bcmath
  php7.2-curl
  php7.2-gd
  php7.2-mbstring
  php7.2-mysql
  php7.2-imap
  php7.2-json
  php7.2-soap
  php7.2-xml
  php7.2-zip
)

### FUNCTIONS

network_detection() {
  # Network Detection
  #
  # Make an HTTP request to ppa.launchpad.net to determine if outside access is available
  # to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
  # skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=10 --spider --recursive --level=2 https://ppa.launchpad.net 2>&1 | grep 'connected')" ]]; then
    echo "Succesful Network connection to ppa.launchpad.net detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach ppa.launchpad.net..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}


package_install() {

  # Update all of the package references before installing anything
  echo "Running apt-get update..."
  apt-get -y update

  # Install required packages
  echo "Installing apt-get packages..."
  apt-get -y install ${apt_package_install_list[@]}
  # Install required packages
  echo "Installing apt-get packages..."
  if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${apt_package_install_list[@]}; then
    echo "Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
    apt-get clean
    return 1
  fi

  # Remove unnecessary packages
  echo "Removing unnecessary packages..."
  apt-get autoremove -y

  # Clean up apt caches
  echo "Cleaning apt caches..."
  apt-get clean

  return 0
}

configure() {
  # Copy nginx configuration from local
  cp "${DIR}/php7.2-upstream.conf" "/etc/nginx/upstreams/php72.conf"

  # Copy php-fpm configuration from local
  cp "${DIR}/php7.2-fpm.conf" "/etc/php/7.2/fpm/php-fpm.conf"
  cp "${DIR}/php7.2-www.conf" "/etc/php/7.2/fpm/pool.d/www.conf"
  cp "${DIR}/php7.2-custom.ini" "/etc/php/7.2/fpm/conf.d/php-custom.ini"
  cp "/srv/config/php-config/opcache.ini" "/etc/php/7.2/fpm/conf.d/opcache.ini"
  cp "/srv/config/php-config/xdebug.ini" "/etc/php/7.2/mods-available/xdebug.ini"
  if [[ -e /srv/config/php-config/mailcatcher.ini ]]; then
    cp "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.2/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php-config/mailcatcher.ini   to /etc/php/7.2/mods-available/mailcatcher.ini"

  fi
  if [[ -e /srv/config/php-config/mailhog.ini ]]; then
    cp "/srv/config/php-config/mailhog.ini" "/etc/php/7.2/mods-available/mailhog.ini"
    echo " * Copied /srv/config/php-config/mailhog.ini   to /etc/php/7.2/mods-available/mailhog.ini"
  fi

  echo " * Copied ${DIR}/php7.2-fpm.conf                   to /etc/php/7.2/fpm/php-fpm.conf"
  echo " * Copied ${DIR}/php7.2-www.conf                   to /etc/php/7.2/fpm/pool.d/www.conf"
  echo " * Copied ${DIR}/php7.2-custom.ini                 to /etc/php/7.2/fpm/conf.d/php-custom.ini"
  echo " * Copied /srv/config/php-config/opcache.ini       to /etc/php/7.2/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php-config/xdebug.ini        to /etc/php/7.2/mods-available/xdebug.ini"

  service php7.2-fpm restart
}

network_check
package_install
configure

echo "PHP 7.2 installed"
