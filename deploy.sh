#!/bin/bash
set -ex
echo "Deploy $0 $@"
curl -sLO  https://github.com/pli01/test/archive/refs/tags/$(curl --silent "https://api.github.com/repos/pli01/test/releases/latest"| jq  -re '.tag_name').tar.gz
exit 0
