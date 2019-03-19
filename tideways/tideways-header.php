<?php

if(strpos($_SERVER['REQUEST_URI'], 'vvv.test') === false && strpos($_SERVER['REQUEST_URI'], 'enable-tideways') !== false) {
    include '/srv/www/default/xhgui/external/header.php';
}

