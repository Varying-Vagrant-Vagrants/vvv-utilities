#!/usr/bin/env bash

# Download and extract phpMemcachedAdmin to provide a dashboard view and
# admin interface to the goings on of memcached when running
echo " * Checking for memcached-admin"
if [[ ! -d "/srv/www/default/memcached-admin" ]]; then
	echo -e " * Downloading phpMemcachedAdmin, see https://github.com/elijaa/phpmemcachedadmin"
	cd /srv/www/default || return 1
	wget -q -O phpmemcachedadmin.tar.gz "https://github.com/wp-cloud/phpmemcacheadmin/archive/1.2.4-vvv.tar.gz"
	tar -xf phpmemcachedadmin.tar.gz
	mv phpmemcacheadmin* memcached-admin
	cp memcached-admin/Config/Memcache.sample.php memcached-admin/Config/Memcache.php
	rm phpmemcachedadmin.tar.gz
else
	echo " * phpMemcachedAdmin already installed."
fi
