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
        $is_vvv_tideways = false;

        if ( empty( $_SERVER['REMOTE_ADDR'] ) and !isset( $_SERVER['HTTP_USER_AGENT'] ) and count( $_SERVER['argv']) > 0 ) {
            // CLI
            if ( isset( $_SERVER['ENABLE_TIDEWAYS_CLI'] ) && $_SERVER['ENABLE_TIDEWAYS_CLI'] === '1' ) {
                $is_vvv_tideways = true;
            }
        } else {
            // Web requests:
            if ( !isset( $_SERVER['HTTP_HOST'] ) ) {
                return false;
            }

            if ( strpos( $_SERVER['HTTP_HOST'], 'vvv.test' ) != false ) {
                return false;
            }
            
            try { 
                if ( file_exists( '/srv/config/tideways.json' ) && 
                    in_array( $_SERVER['HTTP_HOST'], json_decode( file_get_contents( '/srv/config/tideways.json' ) ) ) 
                   ) {
                    $is_vvv_tideways = true;
                }
            }  
            catch (\JsonException $exception) {  
                echo $exception->getMessage() . ' on /srv/config/tideways.json file.';
            }

            if ( isset( $_REQUEST['enable-tideways'] ) && ( $_REQUEST['enable-tideways'] == true ) ) {
                $is_vvv_tideways = true;
            }
        }

        if( ! $is_vvv_tideways ) {
            return false;
        }

        return true;
    },
    'profiler.replace_url' => function($uri) {
        $query = parse_url($uri, PHP_URL_QUERY);
        if ( ! empty( $query ) ) {
            $params = [];
            parse_str( $query, $params );
            if (  ! array_key_exists( 'enable-tideways', $params ) ) {
                return $uri;
            }
            $uri = str_replace('?enable-tideways=' . $params['enable-tideways'], '', $uri);
            $uri = str_replace('%3Fenable-tideways=' . $params['enable-tideways'], '', $uri);
        }
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
