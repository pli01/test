#!/bin/bash
set -x
env |sort
pwd
sudo apt-get install -qy nginx
ifconfig

( no_proxy=169.254.169.254 curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip )
sleep 60
 
exit 0
