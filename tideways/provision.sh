#!/usr/bin/env bash
# Tideways with XHGui
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEFAULTPHP=$(php -r "echo substr(phpversion(),0,3);")

configs=(
  /srv/vvv/config.yml
  /vagrant/config.yml
  /vagrant/vvv-config.yml
)
VVV_CONFIG=/srv/vvv/config.yml
for item in ${configs[*]}; do
  if [[ -f $item ]]; then
    VVV_CONFIG=$item
    break
  fi
done

function fetch_tideways_repo() {
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
    if [[ ! $(command -v php-config$version) ]]; then
        return
    fi
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
        update-alternatives --set php "/usr/bin/php${version}"
        update-alternatives --set php-config "/usr/bin/php-config${version}"
        update-alternatives --set phpize "/usr/bin/phpize${version}"
        "phpize${version}"
        
        # configure and build
        ./configure --enable-tideways-xhprof --with-php-config="php-config${version}"
        make
        make install
        
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
    for version in "7.0" "7.1" "7.2" "7.3" "7.4" "8.0"
    do
        if [[ $(command -v php-fpm$version) ]]; then
            install_tideways_for_php_version "${version}"
        fi
    done
}

function restart_php() {
    echo " * Restarting PHP-FPM server"
    for version in "7.0" "7.1" "7.2" "7.3" "7.4" "8.0"
    do
        if [[ $(command -v php-fpm$version) ]]; then
            service "php${version}-fpm" restart
        fi
    done
    echo " * Restarting Nginx"
    service nginx restart
}

function install_php_sqlite() {
    declare -a packages=()
    for version in "7.0" "7.1" "7.2" "7.3" "7.4" "8.0"; do
        if [[ $(command -v php$version) ]]; then
            packages+=("php${version}-sqlite3")
        fi
    done
    apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken "${packages[@]}"
}

function install_xhgui_frontend() {
    cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
    if [[ ! -d "/srv/www/default/xhgui" ]]; then
        echo -e " * Git cloning xhgui from https://github.com/perftools/xhgui.git"
        cd /srv/www/default
        noroot git clone "https://github.com/perftools/xhgui.git" xhgui
    fi
    cd /srv/www/default/xhgui
    git checkout "0.18.1"
    echo " * Installing xhgui"
    noroot php install.php
    noroot cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"

    if [[ ! -d "/srv/www/default/php-profiler" ]]; then
        echo -e " * Installing php-profiler for Xhgui"
        cd /srv/www/default
        noroot mkdir ./php-profiler && cd ./php-profiler
        echo " * Installing php-profiler"
        noroot composer require --no-update perftools/php-profiler
        noroot composer require --no-update perftools/xhgui-collector
        noroot composer install
    else
        cd /srv/www/default/php-profiler
        noroot composer update
    fi
    noroot cp -f "${DIR}/config.php-profiler.php" "./config.php"
}

function enable_tideways_by_site() {
    echo " * Tideways-by-site started"

    php "${DIR}/by-site.php" "${VVV_CONFIG}"

    echo " * Tideways-by-site finished"
}

echo " * Installing Tideways & XHGui"
fetch_tideways_repo
check_tideways_php
install_php_sqlite
install_xhgui_frontend
enable_tideways_by_site

echo " * Restoring the default PHP CLI version ( ${DEFAULTPHP} )"
update-alternatives --set php "/usr/bin/php${DEFAULTPHP}"
update-alternatives --set phar "/usr/bin/phar${DEFAULTPHP}"
update-alternatives --set phar.phar "/usr/bin/phar.phar${DEFAULTPHP}"
update-alternatives --set phpize "/usr/bin/phpize${DEFAULTPHP}"
update-alternatives --set php-config "/usr/bin/php-config${DEFAULTPHP}"

restart_php

if [[ ! -f "/srv/www/default/xhgui/composer.lock" ]]; then
    echo " * XHGUI installation failed!"
else
    echo " * Tideways and XHGui installed"
fi
