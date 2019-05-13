#!/bin/env php    
<?php 
if(is_file('/srv/tideways.json')) {
    unlink('/srv/tideways.json');
}

$vvv_config = $argv[1];
$config     = yaml_parse_file($vvv_config);
$hosts_list = array();

foreach ($config['sites'] as $domain => $settings) {
    if(isset($settings['tideways'])) {
        $hosts_list = array_merge($hosts_list, $settings['hosts']);
    }
}

$json_data = json_encode($hosts_list);
file_put_contents('/srv/tideways.json', $json_data);
