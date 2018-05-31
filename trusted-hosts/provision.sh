#!/usr/bin/env bash

DIR=`dirname $0`

cp -f ${DIR}/hosts.txt /etc/ssh/ssh_known_hosts
