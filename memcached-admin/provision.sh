#!/usr/bin/env bash

# Download and extract phpMemcachedAdmin to provide a dashboard view and
# admin interface to the goings on of memcached when running
echo " * Checking for memcached-admin"

# Clean up old versions of phpmemcachedadmin that are abandoned, and reinstall.
if [[ -d "/srv/www/default/memcached-admin" ]]; then
	if [[ ! -d "/srv/www/default/memcached-admin/.git" ]]; then
		echo -e " ! Old unsupported version found, removing so that newer supported version can be installed."
		rm -rf "/srv/www/default/memcached-admin"
	fi
fi

if [[ ! -d "/srv/www/default/memcached-admin" ]]; then
	cd /srv/www/default || exit 1
	echo -e " * Downloading phpMemcachedAdmin, see https://github.com/AlexeyPlodenko/phpmemcachedadmin"
	git clone https://github.com/AlexeyPlodenko/phpmemcachedadmin.git memcached-admin
	cd /srv/www/default/memcached-admin || exit 1
	mkdir -p /srv/www/default/memcached-admin/tmp
	composer install
cat <<'EOF' > ".config.php"
<?php
return [
    'temp_dir_path' => '/tmp',
    'servers' => [
        'Default' => [
            'localhost-server' => [
                'hostname' => '127.0.0.1',
                'port' => '11211',
            ],
        ],
    ],
];
EOF
cat <<'EOF' > index.php
<?php
require_once 'src/bootstrap.php';
EOF
else
	cd /srv/www/default/memcached-admin || exit 1
	git pull
	composer install
fi
