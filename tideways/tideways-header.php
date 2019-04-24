<?php

if( file_exists( '/srv/tideways.json' ) && in_array( $_SERVER['HTTP_HOST'], json_decode( file_get_contents( '/srv/tideways.json' ) ) ) || isset( $_SERVER['REQUEST_URI'] ) && strpos( $_SERVER['REQUEST_URI'], 'enable-tideways' ) !== false ) {
    if ( file_exists( '/srv/www/default/xhgui/external/header.php' ) ) {
        include '/srv/www/default/xhgui/external/header.php';
    }

    define( 'QM_DISABLED', true );
    if( file_exists( './custom-header.php' ) ) {
        include_once( './custom-header.php' );
    }
}

