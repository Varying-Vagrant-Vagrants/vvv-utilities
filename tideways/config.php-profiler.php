<?php

require_once 'vendor/autoload.php';

$config = array(
    'save.handler' => \Xhgui\Profiler\Profiler::SAVER_STACK,
    'save.handler.stack' => array(
        'savers' => array(
            \Xhgui\Profiler\Profiler::SAVER_UPLOAD,
            \Xhgui\Profiler\Profiler::SAVER_FILE,
        ),
        // if saveAll=false, break the chain on successful save
        'saveAll' => false,
    ),
    // subhandler specific configs
    'save.handler.file' => array(
        'filename' => '/tmp/xhgui.data.jsonl',
    ),
    'save.handler.upload' => array(
        'uri' => 'http://xhgui.vvv.test/run/import',
        'timeout' => 3,
        'token' => 'token',
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
); 

$custom_args = array();
if( file_exists( './custom-config.php' ) ) {
    include './custom-config.php';
}

try {
    $profiler = new \Xhgui\Profiler\Profiler( array_merge( $config, $custom_args ) );
    $profiler->start();
} catch (Exception $e){
    print_r($e);
    die(); //phpcs:ignore
}
