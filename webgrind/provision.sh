#!/usr/bin/env bash
# Webgrind install (for viewing callgrind/cachegrind files produced by
# xdebug profiler)
DIR=`dirname $0`

# make sure the folder exists and is writable
mkdir -p /srv/www/default/webgrind/

# cleanup .git folder from pre-composer days
if [ -d "/srv/www/default/webgrind/.git" ]; then
  echo "Cleaning up .git folder from pre-composer provisioning"
  rm -r /srv/www/default/webgrind/.git
fi

# phpMyAdmin
echo -e "Installing/Updating webgrind, see https://github.com/jokkedk/webgrind ..."
cd "${DIR}"
composer update --no-autoloader
