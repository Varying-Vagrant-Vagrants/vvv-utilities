<?php

require_once 'vendor/autoload.php';

$config = array(
    'save.handler' => \Xhgui\Profiler\Profiler::SAVER_PDO,
    'save.handler.pdo' => array(
        'dsn' => 'sqlite:/tmp/xhgui.sqlite3',
        'user' => null,
        'pass' => null,
        'table' => 'results'
    ),
    // If defined, use specific profiler
    // otherwise use any profiler that's found
    'profiler' => \Xhgui\Profiler\Profiler::PROFILER_TIDEWAYS_XHPROF,
    // This allows to configure, what profiling data to capture
    'profiler.flags' => array(
        \Xhgui\Profiler\ProfilingFlags::CPU,
        \Xhgui\Profiler\ProfilingFlags::MEMORY,
        \Xhgui\Profiler\ProfilingFlags::NO_BUILTINS,
        \Xhgui\Profiler\ProfilingFlags::NO_SPANS,
    ),
    // Environment variables to exclude from profiling data
    'profiler.exclude-env' => array(
        'APP_DATABASE_PASSWORD',
        'PATH',
    ),
    // Other config
    'profiler.enable' => function() {
        if ( isset( $_SERVER['REQUEST_URI'] ) && strpos( $_SERVER['REQUEST_URI'], 'vvv.test/' ) === 0 ) { //phpcs:ignore
            return false;
        }
        return true;
    },
    'profiler.replace_url' => function($uri) {
        $uri = str_replace('?enable-tideways', '', $uri);
        $uri = str_replace('%3Fenable-tideways', '', $uri);
        return $uri;
    },
    'profiler.simple_url' => function($url) {
        return $url;
    },
    'profiler.options' => array(),
    'profiler.skip_built_in' => false,
    'fastcgi_finish_request' => true,
); 

$custom_args = array();
if( file_exists( './custom-config.php' ) ) {
    include_once './custom-config.php';
}

try {
    $profiler = new \Xhgui\Profiler\Profiler( array_merge( $config, $custom_args ) );
    $profiler->start();
} catch (Exception $e){
    print_r($e);
    die(); //phpcs:ignore
}
