
#!/bin/env php    
<?php 
if(is_file('/srv/config/tideways.json')) {
    unlink('/srv/config/tideways.json');
}

$vvv_config = $argv[1];
if(is_file($vvv_config)) {
    $config     = yaml_parse_file($vvv_config);
    $hosts_list = array();

    foreach ($config['sites'] as $domain => $settings) {
        if(isset($settings['tideways'])) {
            $hosts_list = array_merge($hosts_list, $settings['hosts']);
        }
    }

    $json_data = json_encode($hosts_list);
    file_put_contents('/srv/config/tideways.json', $json_data);
}
