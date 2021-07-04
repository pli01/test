#!/bin/bash
set -e -o pipefail
host_ip=$( ( ifconfig eth0  2>&- || ifconfig en0 2>&- ) | grep "inet.*netmask" | awk ' { print $2 }')
echo "# Get ip ${host_ip}"
