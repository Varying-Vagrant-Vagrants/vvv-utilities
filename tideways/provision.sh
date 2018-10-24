#!/usr/bin/env bash
# Tideways with XHgui
DIR=$(pwd)

install_tideways() {
    # Tideways is only for php =>7.0
    echo "Installing/update Tideways to PHP 7.0, 7.1, 7.2"
    git clone "https://github.com/tideways/php-xhprof-extension" "/var/local/tideways-php7.2"
    cp -r /var/local/tideways-php7.2 /var/local/tideways-php7.0
    cp -r /var/local/tideways-php7.2 /var/local/tideways-php7.1
    for version in 7.0 7.1 7.2
        do
        echo "Compiling Tideways for PHP $version"
        cd "/var/local/tideways-php${version}"
        update-alternatives --set php /usr/bin/php$version > /dev/null 2>&1
        update-alternatives --set php-config /usr/bin/php-config$version > /dev/null 2>&1
        update-alternatives --set phpize /usr/bin/phpize$version > /dev/null 2>&1
        phpize$version
        ./configure --enable-tideways-xhprof --with-php-config=php-config$version > /dev/null 2>&1
        make > /dev/null 2>&1
        make install > /dev/null 2>&1
    done
}

restart_php() {
    if [[ -d "/etc/php/7.0/" ]]; then
        service php7.0-fpm restart
    fi
    if [[ -d "/etc/php/7.1/" ]]; then
        service php7.1-fpm restart
    fi
    if [[ -d "/etc/php/7.2/" ]]; then
        service php7.2-fpm restart
    fi
}

install_mongodb() {
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    sudo apt update > /dev/null 2>&1
    apt-get -y install mongodb-org re2c
    sudo pecl install mongodb
    ln -s /usr/lib/php/20151012/mongodb.so /usr/lib/php/20170718/mongodb.so
    ln -s /usr/lib/php/20160303/mongodb.so /usr/lib/php/20170718/mongodb.so
    phpenmod mongodb
    # auto-remove records older than 2592000 seconds (30 days)
    mongo xhprof --eval 'db.collection.ensureIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1
    # indexes
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().wt' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().mu' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().cpu' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.url' : 1 } )" > /dev/null 2>&1
    update-rc.d mongodb defaults
    update-rc.d mongodb enable
}

echo "Installing Tideways & XHgui"
if [[ ! -d "/srv/www/default/xhgui" ]]; then
    if [[ -d "/etc/php/7.0/" ]]; then
        echo "File copied for php 7.0"
        cp "${DIR}/tideways.ini" "/etc/php/7.0/mods-available/tideways_xhprof.ini"
        cp "${DIR}/mongodb.ini" "/etc/php/7.0/mods-available/mongodb.ini"
        cp "${DIR}/xhgui-php.ini" "/etc/php/7.0/mods-available/xhgui.ini"
    fi
    if [[ -d "/etc/php/7.1/" ]]; then
        echo "File copied for php 7.1"
        cp "${DIR}/tideways.ini" "/etc/php/7.1/mods-available/tideways_xhprof.ini"
        cp "${DIR}/mongodb.ini" "/etc/php/7.1/mods-available/mongodb.ini"
        cp "${DIR}/xhgui-php.ini" "/etc/php/7.1/mods-available/xhgui.ini"
    fi
    if [[ -d "/etc/php/7.2/" ]]; then
        echo "File copied for php 7.2"
        cp "${DIR}/tideways.ini" "/etc/php/7.2/mods-available/tideways_xhprof.ini"
        cp "${DIR}/xhgui-php.ini" "/etc/php/7.2/mods-available/xhgui.ini"
        # For the default php version
        cp "${DIR}/mongodb.ini" "/etc/php/7.2/mods-available/mongodb.ini"
    fi
    install_mongodb
    install_tideways
    phpenmod tideways_xhprof
    echo -e "\nDownloading xhgui, see https://github.com/perftools/xhgui"
    git clone "https://github.com/perftools/xhgui" "/srv/www/default/xhgui"
    cd /srv/www/default/xhgui
    php install.php > /dev/null 2>&1
    cp "${DIR}/vvv-hosts" "/srv/www/default/xhgui/vvv-hosts"
    cp "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
    cp "${DIR}/tideways-header.php" "/srv/www/default/xhgui/config/tideways-header.php"
    cp "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
    restart_php
    service mongodb restart
    if [[ -d "/etc/php/7.0/" ]]; then
        php7.0 --ri tideways_xhprof
    fi
    if [[ -d "/etc/php/7.1/" ]]; then
        php7.1 --ri tideways_xhprof
    fi
    php --ri tideways_xhprof
else
    echo -e "\nUpdating xhgui..."
    cd /srv/www/default/xhgui
    git pull --rebase origin master > /dev/null 2>&1
    rm -rf /var/local/tideways-php7.0
    rm -rf /var/local/tideways-php7.1
    rm -rf /var/local/tideways-php7.2
    install_tideways
    make  > /dev/null 2>&1
    make install  > /dev/null 2>&1
    restart_php
fi

echo "* Added xhgui.vvv.test domain"
