#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo " * Running all PHP provisioners"

( cd "${DIR}/../php56/" && . provision.sh )
( cd "${DIR}/../php70/" && . provision.sh )
( cd "${DIR}/../php71/" && . provision.sh )
( cd "${DIR}/../php72/" && . provision.sh )
( cd "${DIR}/../php73/" && . provision.sh )
( cd "${DIR}/../php74/" && . provision.sh )

echo " * Finished running PHP provisioners"
