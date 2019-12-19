#!/usr/bin/env bash
# Mongodb
export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

install_mongodb_php() {
    for version in "7.0" "7.1" "7.2" "7.3" "7.4"
    do
        if [[ $(command -v php$version) ]]; then
            echo " * Checking MongoDB for PHP ${version}"
            if [ -e "/etc/php/${version}/mods-available/mongodb.ini" ]; then
                echo " * MongoDB PHP v${version} extension is already installed"
            else
                echo " * Installing MongoDB for PHP ${version}"
                sudo pecl -d php_suffix="$version" install mongodb > /dev/null 2>&1
                # do not remove files, only register the packages as not installed so we can install for other php version
                sudo pecl uninstall -r mongodb > /dev/null 2>&1
                cp -f "${DIR}/mongodb.ini" "/etc/php/${version}/mods-available/mongodb.ini"
                phpenmod -v "${version}" mongodb
                echo " * Installed PHP v${version} MongoDB driver"
            fi
        fi
    done
}

install_mongodb() {
    echo " * Installing MongoDB"
    codename=$(lsb_release --codename | cut -f2)
    if [[ $codename == "trusty" ]]; then
        if [[ ! $( apt-key list | grep 'MongoDB 3.4') ]]; then
            apt-key add "${DIR}/server-3.4.asc"
        fi
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    else
        [ -e /etc/apt/sources.list.d/mongodb-org-3.4.list ] && rm /etc/apt/sources.list.d/mongodb-org-3.4.list
        if [[ ! $( apt-key list | grep 'MongoDB 4.0') ]]; then
            apt-key add "${DIR}/server-4.0.asc"
        fi
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu ${codename}/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
    fi

    echo " * Running apt-get update"
    apt-get -y update
    echo " * Installing apt-get packages"
    apt_package_install_list=(
        mongodb-org
        re2c
    )
    if ! apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install --fix-missing --fix-broken ${apt_package_install_list[@]}; then
        echo " * Installing apt-get packages returned a failure code, cleaning up apt caches then exiting"
        apt-get clean
        return 1
    fi
}

cleanup_mongodb_entries() {
    echo " * Auto-removing mongoDB records older than 2592000 seconds (30 days)"
    mongo xhprof --eval 'db.collection.ensureIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )' > /dev/null 2>&1
    # indexes
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().wt' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().mu' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().cpu' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.url' : 1 } )"
}

# Create the log and data directories if they don't exist already
mkdir -p /var/log/mongodb
mkdir -p /data/db

echo " * Making sure mongodb service is enabled"

if [[ ! $(command -v mongo) ]]; then
    install_mongodb
fi
install_mongodb_php
cleanup_mongodb_entries

# make sure mongo can actually write to the log folder
chown mongodb /var/log/mongodb

echo " * Restarting mongod"
systemctl enable mongod.service
systemctl start mongod.service

echo " * MongoDB provisioning complete"
