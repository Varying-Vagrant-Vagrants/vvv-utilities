<?php

if( isset( $_SERVER['REQUEST_URI'] ) && strpos( $_SERVER['REQUEST_URI'], 'enable-tideways' ) !== false ) {
    include '/srv/www/default/xhgui/external/header.php';
}

if( file_exists( './custom-header.php' ) ) {
    include_once( './custom-header.php' );
}
