#!/usr/bin/env bash

echo " * Running all PHP provisioners"

(cd ../php56 && source provision.sh )
(cd ../php70 && source provision.sh )
(cd ../php71 && source provision.sh )
(cd ../php72 && source provision.sh )
(cd ../php73 && source provision.sh )
(cd ../php74 && source provision.sh )

echo " * Finished running PHP provisioners"
