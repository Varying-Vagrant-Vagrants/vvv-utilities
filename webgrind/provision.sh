#!/usr/bin/env bash
# Webgrind install (for viewing callgrind/cachegrind files produced by
# xdebug profiler)
DIR=`dirname $0`

# phpMyAdmin
echo -e "Install/Update webgrind, see https://github.com/jokkedk/webgrind ..."
cd "${DIR}"
composer update --no-autoloader
