<?php

$defaults = array(
    'debug' => false,
    'save.handler' => 'pdo',
    'pdo' => array(
        'dsn' => 'sqlite:/tmp/xhgui.sqlite3',
        'user' => null,
        'pass' => null,
        'table' => 'results',
        'tableWatch' => 'watches'
    ),
    'templates.path' => dirname(__DIR__) . '/src/templates',
    'date.format' => 'M jS H:i:s',
    'detail.count' => 6,
    'page.limit' => 25,
    'run.view.filter.names' => array(
        'wp_*',
        'Composer*',
    ),
);

$custom_args = array();
if( file_exists( './custom-config.php' ) ) {
    include_once './custom-config.php';
}

// In config/config.php
return array_merge( $defaults, $custom_args );
