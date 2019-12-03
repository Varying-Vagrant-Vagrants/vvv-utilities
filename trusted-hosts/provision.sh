#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cp -f "${DIR}/hosts.txt" /etc/ssh/ssh_known_hosts
