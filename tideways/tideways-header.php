<?php

$is_vvv_tideways = false;

if ( empty( $_SERVER['REMOTE_ADDR'] ) and !isset( $_SERVER['HTTP_USER_AGENT'] ) and count( $_SERVER['argv']) > 0 ) {
    // CLI
    if ( isset( $_SERVER['ENABLE_TIDEWAYS_CLI'] ) && $_SERVER['ENABLE_TIDEWAYS_CLI'] === '1' ) {
        $is_vvv_tideways = true;
    }
} else {
    // Web requests:
    if ( !isset( $_SERVER['HTTP_HOST'] ) ) {
        return;
    }

    if ( strpos( $_SERVER['HTTP_HOST'], 'vvv.test' ) != false ) {
        return;
    }

    if ( file_exists( '/srv/config/tideways.json' ) && in_array( $_SERVER['HTTP_HOST'], json_decode( file_get_contents( '/srv/config/tideways.json' ) ) ) ) {
        $is_vvv_tideways = true;
    }

    if ( isset( $_REQUEST['enable-tideways'] ) && ( $_REQUEST['enable-tideways'] == true ) ) {
        $is_vvv_tideways = true;
    }
}

if( ! $is_vvv_tideways ) {
    return;
}

if ( file_exists( '/srv/www/default/php-profiler/config.php' ) ) {
    include '/srv/www/default/php-profiler/config.php';
}

// Disable Query monitor when using TIdeways/XHGUI PHP Profiler
define( 'QM_DISABLED', true );
