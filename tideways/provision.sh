#!/usr/bin/env bash
# Tideways with XHgui
DIR=`dirname $0`

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
    version=$1
    if [[ `command -v php$version` ]]; then
        echo "Copying tideways files for php $version"
        cp -f "${DIR}/tideways.ini" "/etc/php/$version/mods-available/tideways_xhprof.ini"
        cp -f "${DIR}/xhgui-php.ini" "/etc/php/$version/mods-available/xhgui.ini"
        cp -rf /var/local/tideways-php /var/local/tideways-php$version
        echo "Compiling Tideways for PHP $version"
        cd "/var/local/tideways-php${version}"
        update-alternatives --set php /usr/bin/php$version > /dev/null 2>&1
        update-alternatives --set php-config /usr/bin/php-config$version > /dev/null 2>&1
        update-alternatives --set phpize /usr/bin/phpize$version > /dev/null 2>&1
        phpize$version
        ./configure --enable-tideways-xhprof --with-php-config=php-config$version > /dev/null 2>&1
        make > /dev/null 2>&1
        make install > /dev/null 2>&1
    fi
}

restart_php() {
    for version in 7.0 7.1 7.2 7.3
    do
        if [[ `command -v php$version` ]]; then
            service php$version-fpm restart
        fi
    done
    service nginx restart
}

install_mongodb() {
    apt-key add "${DIR}/aptkey.pgp"
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    sudo apt update > /dev/null 2>&1
    apt-get -y install mongodb-org re2c
    for version in 7.0 7.1 7.2 7.3
    do
        if [[ `command -v php$version` ]]; then
            sudo pecl -d php_suffix=$version install mongodb
            cp -f "${DIR}/mongodb.ini" "/etc/php/$version/mods-available/mongodb.ini"
        fi
    done
    phpenmod -v $version mongodb
    # auto-remove records older than 2592000 seconds (30 days)
    mongo xhprof --eval 'db.collection.ensureIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1
    # indexes
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().wt' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().mu' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().cpu' : -1 } )" > /dev/null 2>&1
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.url' : 1 } )" > /dev/null 2>&1
    update-rc.d mongodb defaults
    service mongod restart
}

echo "Installing Tideways & XHgui"
if [[ ! `command -v mongo` ]]; then
    install_mongodb
fi
install_tideways
for version in 7.0 7.1 7.2 7.3
do
    if [[ `command -v php$version` ]]; then
        install_tideways_php $version
    fi
done
phpenmod tideways_xhprof

if [[ ! -d "/srv/www/default/xhgui" ]]; then
    echo -e "\nDownloading xhgui, see https://github.com/perftools/xhgui"
    git clone "https://github.com/perftools/xhgui" "/srv/www/default/xhgui"
    cd /srv/www/default/xhgui
    sudo php install.php > /dev/null 2>&1
    cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
    cp -f "${DIR}/tideways-header.php" "/srv/www/default/xhgui/config/tideways-header.php"
    cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
    restart_php
    service mongodb restart
    for version in 7.0 7.1 7.2 7.3
    do
        if [[ `command -v php$version` ]]; then
            php$version --ri tideways_xhprof
        fi
    done
    php --ri tideways_xhprof
else
    echo -e "\nUpdating xhgui..."
    cd /srv/www/default/xhgui
    git pull --rebase origin master > /dev/null 2>&1
    for version in 7.0 7.1 7.2 7.3
    do
        if [[ -d "/var/local/tideways-php$version" ]]; then
            rm -rf /var/local/tideways-php$version
        fi
    done
    install_tideways
    for version in 7.0 7.1 7.2 7.3
    do
        if [[ `command -v php$version` ]]; then
            install_tideways_php $version
        fi
    done
    make  > /dev/null 2>&1
    make install  > /dev/null 2>&1
    restart_php
fi

