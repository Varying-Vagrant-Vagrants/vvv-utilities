#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# @TODO: retrieve major version from config.yml
ESMAJORVERSION="7"

elastic_apt_package_install_list=(
  "apt-transport-https"
  "openjdk-11-jre"
  "elasticsearch"
)

### FUNCTIONS

package_install() {

  echo " * Installing Elastic Search v${ESMAJORVERSION}."
  echo "   - Note: To change versions you need to manually uninstall elastic before reprovisioning"

  if [[ ! $( apt-key list | grep 'Elasticsearch') ]]; then
    echo " * Adding Elastic GPG Apt key"
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
  fi
  echo " * Adding apt source https://artifacts.elastic.co/packages/${ESMAJORVERSION}.x/apt stable main"
  echo "deb https://artifacts.elastic.co/packages/${ESMAJORVERSION}.x/apt stable main" | sudo tee "/etc/apt/sources.list.d/vvv-elastic.list"

  # Update all of the package references before installing anything
  echo " * Running apt-get update..."
  apt-get -y update

  # Install required packages
  echo " * Installing apt-get packages..."
  if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${elastic_apt_package_install_list[@]}; then
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

  sudo update-rc.d elasticsearch defaults 95 10

  return 0
}

package_install
echo " * Restarting Elastic Search"
sudo service "elasticsearch" restart
echo " * Elastic Search restarted"
