#!/bin/bash
set -x
env |sort
pwd
apt-get install -qy nginx
ifconfig

( no_proxy=169.254.169.254 wget -q -O -  http://169.254.169.254/latest/meta-data/ )
 
exit 0
