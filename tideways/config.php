<?php

$defaults = array(
    'debug' => false,

    // Can be either mongodb or file.
    'save.handler' => 'mongodb',

    // Needed for file save handler. Beware of file locking. You can adujst this file path
    // to reduce locking problems (eg uniqid, time ...)
    //'save.handler.filename' => __DIR__.'/../data/xhgui_'.date('Ymd').'.dat',
    'db.host' => 'mongodb://127.0.0.1:27017',
    'db.db' => 'xhprof',

    'templates.path' => dirname(__DIR__) . '/src/templates',
    'date.format' => 'M jS H:i:s',
    'detail.count' => 6,
    'page.limit' => 25,
    // Other config
    'profiler.enable' => function() {
        $url = $_SERVER['REQUEST_URI'];
        if (strpos($url, 'vvv.test/') === 0) {
            return false;
        }
        return true;
    },
    'profiler.replace_url' => function($uri) {
        $uri = str_replace('?enable-tideways', '', $uri);
        $uri = str_replace('%3Fenable-tideways', '', $uri);
        return $uri;
    }
);

$custom_args = array();
if( file_exists( './custom-config.php' ) ) {
    include_once( './custom-config.php' );
}

// In config/config.php
return array_merge( $defaults, $custom_args );
