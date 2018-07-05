#!/usr/bin/env bash
# Webgrind install (for viewing callgrind/cachegrind files produced by
# xdebug profiler)
if [[ ! -d "/srv/www/default/xhgui" ]]; then
    echo -e "\nDownloading xhgui, see https://github.com/perftools/xhgui"
    git clone "https://github.com/perftools/xhgui" "/srv/www/default/xhgui"
    chmod -r 775 /srv/www/default/xhgui/cache
    apt-get -y install mongodb
    # auto-remove records older than 2592000 seconds (30 days)
    mongo xhprof --eval 'db.collection.ensureIndex( { "meta.request_ts" : 1 }, { expireAfterSeconds : 2592000 } )'

    # indexes
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.SERVER.REQUEST_TIME' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().wt' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().mu' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'profile.main().cpu' : -1 } )"
    mongo xhprof --eval  "db.collection.ensureIndex( { 'meta.url' : 1 } )"
    # install tideways
    # edit nginx to add fastcgi_param PHP_VALUE "auto_prepend_file=/app/xhgui/external/header.php";
    # Tideways is only for php =>7.0
else
    echo -e "\nUpdating tideways..."
    cd /srv/www/default/xhgui
    git pull --rebase origin master
fi
