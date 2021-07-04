#!/bin/bash
set -x

cluster_name="${APP}-ci"

helm=$(type -p helm)
kubectl=$(type -p kubectl)

# clean
k3d cluster delete ${cluster_name}
