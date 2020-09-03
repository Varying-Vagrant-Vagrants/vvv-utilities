#!/usr/bin/env bash
# Tideways with XHGui
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function install_tideways() {
    if [[ ! -d /var/local/tideways-php/.git ]]; then
        echo " * Cloning Tideways extension"
        git clone "https://github.com/tideways/php-xhprof-extension" /var/local/tideways-php
    else
        echo " * Updating Tideways extension"
        ( cd /var/local/tideways-php/ && git pull -q && git checkout -q )
    fi
}

function install_tideways_for_php_version() {
    version=$1
    echo " * Installing Tideways for PHP ${version}"
    php_modules_path=$("php-config${version}" --extension-dir)
    echo " * Copying tideways files for PHP ${version}"
    cp -f "${DIR}/tideways.ini" "/etc/php/${version}/mods-available/tideways_xhprof.ini"
    cp -f "${DIR}/xhgui-php.ini" "/etc/php/${version}/mods-available/xhgui.ini"
    if [[ ! -f "${php_modules_path}/tideways_xhprof.so" ]] || [[ $(stat -c %Y "${php_modules_path}/tideways_xhprof.so") -lt $(stat -c %Y "/var/local/tideways-php/.git/info/") ]]; then
        echo " * Compiling Tideways for PHP ${version}"
        cp -rf /var/local/tideways-php "/var/local/tideways-php${version}"
        cd "/var/local/tideways-php${version}"

        # switch to PHP version we're building for
        update-alternatives --set php "/usr/bin/php${version}" > /dev/null 2>&1
        update-alternatives --set php-config "/usr/bin/php-config${version}" > /dev/null 2>&1
        update-alternatives --set phpize "/usr/bin/phpize${version}" > /dev/null 2>&1
        "phpize${version}" > /dev/null 2>&1
        
        # configure and build
        ./configure --enable-tideways-xhprof --with-php-config="php-config${version}" > /dev/null 2>&1
        make > /dev/null 2>&1
        make install > /dev/null 2>&1
        
        # perform cleanup
        cd "${DIR}"
        rm -rf "/var/local/tideways-php${version}"
    fi
    phpenmod -v "$version" tideways_xhprof
    phpenmod -v "$version" xhgui
}

function check_tideways_php() {
    cp -f "${DIR}/tideways-header.php" "/srv/tideways-header.php"
    # Tideways is only for php =>7.0
    for version in "7.0" "7.1" "7.2" "7.3" "7.4"
    do
        if [[ $(command -v php$version) ]]; then
            install_tideways_for_php_version "${version}"
        fi
    done
}

function restart_php() {
    echo " * Restarting PHP-FPM server"
    for version in "7.0" "7.1" "7.2" "7.3" "7.4"
    do
        if [[ $(command -v php$version) ]]; then
            service "php${version}-fpm" restart > /dev/null 2>&1
        fi
    done
    echo " * Restarting Nginx"
    service nginx restart > /dev/null 2>&1
}

function install_xhgui_frontend() {
    cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
    if [[ ! -d "/srv/www/default/xhgui" ]]; then
        echo -e " * Git cloning xhgui from https://github.com/perftools/xhgui.git"
        cd /srv/www/default
        git clone "https://github.com/perftools/xhgui.git" xhgui
        cd xhgui
        echo " * Installing xhgui"
        sudo php install.php
        cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
    else
        echo -e " * Updating xhgui..."
        cd /srv/www/default/xhgui
        git pull --rebase origin master > /dev/null 2>&1
        noroot composer update --prefer-dist > /dev/null 2>&1
    fi
    if [[ ! -d "/srv/www/default/php-profiler" ]]; then
        echo -e " * Git cloning php-profiler for Xhgui from https://github.com/perftools/php-profiler.git"
        apt install php-sqlite3 -y
        cd /srv/www/default
        git clone "https://github.com/perftools/php-profiler.git" php-profiler
        cd php-profiler
        echo " * Installing php-profiler"
        composer require perftools/php-profiler
        composer require perftools/xhgui-collector
    fi
}

function enable_tideways_by_site() {
    echo " * Tideways-by-site started"

    VVV_CONFIG=/vagrant/vvv-custom.yml
    if [[ -f /vagrant/config.yml ]]; then
        VVV_CONFIG=/vagrant/config.yml
    fi
    php "${DIR}/by-site.php" "${VVV_CONFIG}"

    echo " * Tideways-by-site finished"
}

# Set DIR back to undo the DIR set in the MongoDB provisioner
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo " * Installing Tideways & XHGui"
install_tideways
check_tideways_php
install_xhgui_frontend
enable_tideways_by_site
restart_php

echo " * Tideways and XHGui installed"
