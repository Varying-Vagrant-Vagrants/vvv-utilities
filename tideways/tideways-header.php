<?php

$is_vvv_tideways = false;
if ( file_exists( '/srv/config/tideways.json' ) && in_array( $_SERVER['HTTP_HOST'], json_decode( file_get_contents( '/srv/config/tideways.json' ) ) ) ) {
    $is_vvv_tideways = true;
}
    
if ( isset( $_SERVER['REQUEST_URI'] ) && strpos( $_SERVER['REQUEST_URI'], 'enable-tideways' ) !== false ) {
    $is_vvv_tideways = true;
}

if( $is_vvv_tideways ) {
    if ( file_exists( '/srv/www/default/xhgui/external/header.php' ) ) {
        include '/srv/www/default/xhgui/external/header.php';
    }

    define( 'QM_DISABLED', true );
    if( file_exists( '/srv/www/default/xhgui/config/custom-header.php' ) ) {
        include_once( '/srv/www/default/xhgui/config/custom-header.php' );
    }
}

