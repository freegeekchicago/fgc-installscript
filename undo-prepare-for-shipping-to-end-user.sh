#!/bin/bash
# This script attempts to undo the results of oem-config-prepare, which is called 
# when a user clicks 'Prepare for shipping to end user'
if [ "$(id -u)" = 0 ]; then
    set -x # For easier debugging, print commands as they run
    /bin/systemctl disable oem-config.service
    /bin/systemctl disable oem-config.target
    rm -f /lib/systemd/system/oem-config.service /lib/systemd/system/oem-config.target
else
    echo "Error: This script must be run as root. try running:"
    echo "sudo $0"
    exit 1
fi     