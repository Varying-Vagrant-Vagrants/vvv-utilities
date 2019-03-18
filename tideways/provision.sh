#!/usr/bin/env bash
# Tideways with XHgui
DIR=$(dirname "$0")

install_tideways() {
    # Tideways is only for php =>7.0
    if [[ ! -d /var/local/tideways-php/.git ]]; then
        echo "Cloning Tideways extension"
        git clone "https://github.com/tideways/php-xhprof-extension" /var/local/tideways-php
    else
        echo "Updating Tideways extension"
        ( cd /var/local/tideways-php/ && git pull -q && git checkout -q )
    fi
}

install_tideways_php() {
    echo "Installing Tideways for PHP $version"
    for version in "7.0" "7.1" "7.2" "7.3"
    do
        if [[ $(command -v php$version) ]]; then
            echo "Copying tideways files for PHP $version"
            cp -f "${DIR}/tideways.ini" "/etc/php/$version/mods-available/tideways_xhprof.ini"
            cp -f "${DIR}/xhgui-php.ini" "/etc/php/$version/mods-available/xhgui.ini"
            cp -rf /var/local/tideways-php "/var/local/tideways-php$version"
            echo "Compiling Tideways for PHP $version"
            cd "/var/local/tideways-php${version}"
            update-alternatives --set php "/usr/bin/php$version" > /dev/null 2>&1
            update-alternatives --set php-config "/usr/bin/php-config$version" > /dev/null 2>&1
            update-alternatives --set phpize "/usr/bin/phpize$version" > /dev/null 2>&1
            phpize$version > /dev/null 2>&1
            ./configure --enable-tideways-xhprof --with-php-config=php-config$version > /dev/null 2>&1
            make > /dev/null 2>&1
            make install > /dev/null 2>&1        
            phpenmod -v "$version" tideways_xhprof
            rm -rf "/var/local/tideways-php$version"
        fi
    done
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
        echo -e "\nDownloading xhgui, see https://github.com/perftools/xhgui"
        git clone "https://github.com/perftools/xhgui" "/srv/www/default/xhgui" > /dev/null 2>&1
        cd /srv/www/default/xhgui
        echo "Installing Tideways"
        sudo php install.php > /dev/null 2>&1
        cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
        cp -f "${DIR}/tideways-header.php" "/srv/www/default/xhgui/config/tideways-header.php"
        cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
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
install_tideways
install_tideways_php
install_xhgui
if [[ $(command -v mongo) ]]; then
    echo "Critical Error!! MongoDB is needed for XHGUI/Tideways support, add mongodb to your vvv-custom.yml utilities section then reprovision"
    exit 1
fi
restart_php

echo "Tideways and xhgui installed"
