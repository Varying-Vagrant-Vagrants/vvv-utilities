<?php

if ( !empty( $_REQUEST['enable-tideways'] ) && ( $_REQUEST['enable-tideways'] == true ) ) {

    if ( file_exists( '/srv/www/default/xhgui/external/header.php' ) ) {
        include '/srv/www/default/xhgui/external/header.php';
    }

    define( 'QM_DISABLED', true );
    if( file_exists( './custom-header.php' ) ) {
        include_once( './custom-header.php' );
    }
}

