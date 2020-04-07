<?php

if ( ! extension_loaded( 'tideways_xhprof' ) ) {
    return;
}

// don't run on CLI
if ( empty($_SERVER['REMOTE_ADDR']) and !isset($_SERVER['HTTP_USER_AGENT']) and count($_SERVER['argv']) > 0) {
    return;
}

if ( !isset( $_SERVER['HTTP_HOST'] ) ) {
    return;
}
if ( strpos( $_SERVER['HTTP_HOST'], 'vvv.test' ) != false ) {
    return;
}

$is_vvv_tideways = false;

if ( file_exists( '/srv/config/tideways.json' ) && in_array( $_SERVER['HTTP_HOST'], json_decode( file_get_contents( '/srv/config/tideways.json' ) ) ) ) {
    $is_vvv_tideways = true;
}

if ( isset( $_REQUEST['enable-tideways'] ) && ( $_REQUEST['enable-tideways'] == true ) ) {
    $is_vvv_tideways = true;
}

if( ! $is_vvv_tideways ) {
    return;
}
if ( file_exists( '/srv/www/default/xhgui/external/header.php' ) ) {
    include '/srv/www/default/xhgui/external/header.php';
}

define( 'QM_DISABLED', true );
if( file_exists( '/srv/www/default/xhgui/config/custom-header.php' ) ) {
    include_once '/srv/www/default/xhgui/config/custom-header.php';
}
