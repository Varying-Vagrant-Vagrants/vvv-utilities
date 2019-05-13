#!/usr/bin/env bash
# Tideways with XHgui
DIR=$(dirname "$0")

enable_tideways_by_site() {
    rm /srv/tideways.json

    domains=""
    input=$(cat "${VVV_CONFIG}")
    sites=$(echo "$input" | shyaml keys-0 sites | xargs -0 -n 1 echo "")

    for value in ${sites}; do
        domain=$(echo "$value" | tr -d '[:space:]')
        tideways=$(echo "$input" | shyaml -q get-value sites."$domain".tideways)
        if [[ $tideways != "" ]]; then
            hosts=$(echo "$input" | shyaml -q get-value sites."$domain".hosts)
            domains="$domains${hosts/\- /''}\n"
        fi
    done
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'      # Change IFS to new line
    domains=("$domains")
    IFS=$SAVEIFS   # Restore IFS
    printf "${domains[@]}" | jq -R . | jq -s . > /srv/tideways.json
}

sudo apt install jq
enable_tideways_by_site

echo "Tideways and xhgui installed"
