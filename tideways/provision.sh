#!/usr/bin/env bash
# Tideways with XHgui
DIR=$(dirname "$0")

install_tideways() {
    if [[ ! -f '/etc/init.d/tideways-daemon' ]]; then
        apt-key add "${DIR}/aptkey.pgp"
        echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' | sudo tee /etc/apt/sources.list.d/tideways.list
        sudo apt update > /dev/null 2>&1
        apt-get -y install tideways-php tideways-daemon > /dev/null 2>&1
        for version in "7.0" "7.1" "7.2" "7.3"
        do
            if [[ $(command -v php$version) ]]; then
                cp -f "${DIR}/xhgui-php.ini" "/etc/php/$version/mods-available/xhgui.ini"
                phpenmod -v "$version" xhgui
            fi
        done
    fi
}

restart_php() {
    echo "Restarting PHP-FPM server"
    for version in "7.0" "7.1" "7.2" "7.3"
    do
        if [[ $(command -v php$version) ]]; then
            service "php$version-fpm" restart > /dev/null 2>&1
        fi
    done
    echo "Restarting Nginx"
    service nginx restart > /dev/null 2>&1
}

install_xhgui() {
    if [[ ! -d "/srv/www/default/xhgui" ]]; then
        echo -e "\nGit cloning xhgui from https://github.com/perftools/xhgui.git"
        cd /srv/www/default
        git clone "https://github.com/perftools/xhgui.git" xhgui
        cd xhgui
        echo "Installing xhgui"
        sudo php install.php
        cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
        cp -f "${DIR}/tideways-header.php" "/srv/www/default/xhgui/config/tideways-header.php"
        echo "Restarting MongoDB"
        service mongod restart
    else
        echo -e "\nUpdating xhgui..."
        cd /srv/www/default/xhgui
        git pull --rebase origin master > /dev/null 2>&1
        sudo php install.php > /dev/null 2>&1
    fi
}

echo "Installing Tideways & XHgui"
if [[ ! $(command -v mongo) ]]; then
    echo "MongoDB is needed for XHGUI/Tideways support, provisioning MongoDB"
    . "${DIR}/../mongodb/provision.sh"
fi
install_tideways
install_xhgui
cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
restart_php

echo "Tideways and xhgui installed"
