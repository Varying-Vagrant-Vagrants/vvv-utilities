<?php

if ( file_exists( '/srv/www/default/php-profiler/config.php' ) ) {
    include '/srv/www/default/php-profiler/config.php';
}

// Disable Query monitor when using TIdeways/XHGUI PHP Profiler
define( 'QM_DISABLED', true );
