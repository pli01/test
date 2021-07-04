#!/bin/bash
#
# install k3d for ci
#
set -e
set -o pipefail
[ -n "$DEBUG" ]&& set -x

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
K3D_VERSION=${K3D_VERSION:-v4.4.4}
K3D_URL=https://raw.githubusercontent.com/rancher/k3d/main/install.sh
HELM_URL=https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$OS/amd64/kubectl

cluster_name="${APP}-ci"

# get k3d
echo "# Download k3d"
curl -sL ${K3D_URL} | \
  TAG=${K3D_VERSION} bash

echo "# Download helm"
curl -fsSL ${HELM_URL} | \
  bash
# To install helm in current dir as user replace with
#  HELM_INSTALL_DIR="." USE_SUDO="false" bash
export helm=$(type -p helm)

echo "# Download kubectl"
curl -fsSLO ${KUBECTL_URL}
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
export kubectl=$(type -p kubectl)

echo "# Get cli version"
# Get version
k3d --version
$helm version
# Client version
$kubectl version --client=true
