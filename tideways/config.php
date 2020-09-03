<?php

$defaults = array(
    'debug' => false,
    'save.handler' => 'sqlite',
    'pdo' => array(
        'dsn' => 'sqlite:/tmp/xhgui.sqlite3',
        'user' => null,
        'pass' => null,
        'table' => 'results'
    ),
    'templates.path' => dirname(__DIR__) . '/src/templates',
    'date.format' => 'M jS H:i:s',
    'detail.count' => 6,
    'page.limit' => 25,
    'run.view.filter.names' => array(
        'wp_*',
        'Composer*',
    ),
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
    include_once './custom-config.php';
}

// In config/config.php
return array_merge( $defaults, $custom_args );
