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
    echo "Install Tideways for PHP $version"
    for version in "7.0" "7.1" "7.2" "7.3"
    do
        if [[ $(command -v php$version) ]]; then
            echo "Copying tideways files for php $version"
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
    service nginx restart > /dev/null 2>&1
}

install_mongodb() {
    if [[ ! $(command -v mongo) ]]; then
        echo "Install MongoDB"
        apt-key add "${DIR}/aptkey.pgp"
        echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
        sudo apt update > /dev/null 2>&1
        apt-get -y install mongodb-org re2c
        # pecl install only on the latest version, on multiple doesn't enable to register to all of them
        sudo pecl install mongodb > /dev/null 2>&1
        for version in "20170718" "20160303" "20151012"
        do
            if [[ $(command -v php$version) ]]; then
                echo "Install MongoDB for PHP $version"
                ln -s /usr/lib/php/20180731/mongodb.so "/usr/lib/php/$version/mongodb.so"
                cp -f "${DIR}/mongodb.ini" "/etc/php/$version/mods-available/mongodb.ini"
                phpenmod -v "$version" mongodb
            fi
        done
        # auto-remove records older than 2592000 seconds (30 days)
        mongo xhprof --eval 'db.collection.ensureIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1
        # indexes
        mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )" > /dev/null 2>&1
        mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().wt' : -1 } )" > /dev/null 2>&1
        mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().mu' : -1 } )" > /dev/null 2>&1
        mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().cpu' : -1 } )" > /dev/null 2>&1
        mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.url' : 1 } )" > /dev/null 2>&1
        service mongod restart
    fi
}

install_xhgui() {
    if [[ ! -d "/srv/www/default/xhgui" ]]; then
        echo -e "\nDownloading xhgui, see https://github.com/perftools/xhgui"
        git clone "https://github.com/perftools/xhgui" "/srv/www/default/xhgui" > /dev/null 2>&1
        cd /srv/www/default/xhgui
        echo "Installing Tideways"
        sudo php install.php
        cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
        cp -f "${DIR}/tideways-header.php" "/srv/www/default/xhgui/config/tideways-header.php"
        cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
        service mongod restart
    else
        echo -e "\nUpdating xhgui..."
        cd /srv/www/default/xhgui
        git pull --rebase origin master > /dev/null 2>&1
    fi
}

echo "Installing Tideways & XHgui"
install_mongodb
install_xhgui
install_tideways
install_tideways_php
restart_php

echo "Finish installation of Tideways with xhgui"
