#!/usr/bin/env bash
# Tideways with XHgui
DIR=$(dirname "$0")

install_tideways() {
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
    cp -f "${DIR}/tideways-header.php" "/srv/tideways-header.php"
    # Tideways is only for php =>7.0
    for version in "7.0" "7.1" "7.2" "7.3"
    do
        if [[ $(command -v php$version) ]]; then
            php_modules_path=$(php-config$version --extension-dir)
            echo "Copying tideways files for PHP $version"
            cp -f "${DIR}/tideways.ini" "/etc/php/$version/mods-available/tideways_xhprof.ini"
            cp -f "${DIR}/xhgui-php.ini" "/etc/php/$version/mods-available/xhgui.ini"
            if [[ ! -f "$php_modules_path/tideways_xhprof.so" ]] || [[ $(stat -c %Y "$php_modules_path/tideways_xhprof.so") -lt $(stat -c %Y "/var/local/tideways-php/.git/info/") ]]; then
                echo "Compiling Tideways for PHP $version"
                cp -rf /var/local/tideways-php "/var/local/tideways-php$version"
                cd "/var/local/tideways-php${version}"
                update-alternatives --set php "/usr/bin/php$version" > /dev/null 2>&1
                update-alternatives --set php-config "/usr/bin/php-config$version" > /dev/null 2>&1
                update-alternatives --set phpize "/usr/bin/phpize$version" > /dev/null 2>&1
                phpize$version > /dev/null 2>&1
                ./configure --enable-tideways-xhprof --with-php-config=php-config$version > /dev/null 2>&1
                make > /dev/null 2>&1
                make install > /dev/null 2>&1
                rm -rf "/var/local/tideways-php$version"
            fi
            phpenmod -v "$version" tideways_xhprof
            phpenmod -v "$version" xhgui
            
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
        echo -e "\nGit cloning xhgui from https://github.com/perftools/xhgui.git"
        cd /srv/www/default
        git clone "https://github.com/perftools/xhgui.git" xhgui
        cd xhgui
        echo "Installing xhgui"
        sudo php install.php
        cp -f "${DIR}/config.php" "/srv/www/default/xhgui/config/config.php"
        echo "Restarting MongoDB"
        service mongod restart
    else
        echo -e "\nUpdating xhgui..."
        cd /srv/www/default/xhgui
        git pull --rebase origin master > /dev/null 2>&1
        sudo php install.php > /dev/null 2>&1
    fi
}

enable_tideways_by_site() {
    rm /srv/tideways.json

    domains=""
    input=$(cat "${VVV_CONFIG}")
    sites=$(echo "$input" | shyaml keys-0 sites | xargs -0 -n 1 echo "")

    for value in ${sites}; do
        domain=$(echo "$value" | tr -d '[:space:]')
        tideways=$(echo "$input" | shyaml -q get-value sites."$domain".tideways)
        if [[ $tideways != "" ]]; then
            hosts=$(echo "$input" | shyaml -q get-value sites."$domain".hosts)
            domains="$domains${hosts/\- /''}\n"
        fi
    done
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'      # Change IFS to new line
    domains=("$domains")
    IFS=$SAVEIFS   # Restore IFS
    printf "${domains[@]}" | jq -R . | jq -s . > /srv/tideways.json
}

echo "Installing Tideways & XHgui"
if [[ ! $(command -v mongo) ]]; then
    echo "MongoDB is needed for XHGUI/Tideways support, provisioning MongoDB"
    . "${DIR}/../mongodb/provision.sh"
fi
DIR=$(dirname "$0")
install_tideways
install_tideways_php
install_xhgui
cp -f "${DIR}/nginx.conf" "/etc/nginx/custom-utilities/xhgui.conf"
enable_tideways_by_site
restart_php

echo "Tideways and xhgui installed"
