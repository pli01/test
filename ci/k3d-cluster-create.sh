#!/bin/bash
set -x

cluster_name="${APP}-ci"

helm=$(type -p helm)
kubectl=$(type -p kubectl)

## create cluster
echo "# Config k3d (traefik v2, calico)"
# replace default ingress with traefik v2
cat >helm-ingress-traefik.yaml <<EOF
# see https://rancher.com/docs/k3s/latest/en/helm/
# see https://github.com/traefik/traefik-helm-chart
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ingress-controller-traefik
  namespace: kube-system
spec:
  repo: https://helm.traefik.io/traefik
  chart: traefik
  version: 9.8.0
  targetNamespace: kube-system
EOF

# replace flanel with calico
curl -sSLO https://k3d.io/usage/guides/calico.yaml

# Create a cluster, api 6443, mapping the ingress port 80 to localhost:80 and 443 to 443
#  1 server, 1 agent, traefik v2 and calico
echo "# Create k3d cluster ${cluster_name}"
if [ -n "$http_proxy" ] ; then
  k3d_args="$k3d_args -e \"HTTP_PROXY=${http_proxy}@all\""
fi
if [ -n "$https_proxy" ] ; then
  k3d_args="$k3d_args -e \"HTTPS_PROXY=${https_proxy}@all\""
fi
if [ -n "$no_proxy" ] ; then
  k3d_args="$k3d_args -e \"NO_PROXY=${no_proxy}@all\""
fi


# get local private ip
cluster_port=6443
cluster_ip=$(dirname $(ip add |egrep 'inet.*eth0' | awk ' { print $2 } ' ))

images_dir="$(pwd)/images"
[ -d "$images_dir" ] || mkdir -p $images_dir

#  TODO: use calico / traefik v2
#   --volume "$(pwd)/calico.yaml:/var/lib/rancher/k3s/server/manifests/calico.yaml" \
#   --volume "$(pwd)/helm-ingress-traefik.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-traefik.yaml" \
#   --k3s-server-arg '--no-deploy=traefik --flannel-backend=none' \


k3d cluster create ${cluster_name} \
   --api-port "${cluster_ip}:${cluster_port}" \
   --port 80:80@loadbalancer \
   --servers 1 --agents 1 \
   --registry-create \
   --volume "${images_dir}:/var/lib/rancher/k3s/agent/images@all" \
   $k3d_args \
   --wait

docker ps

$kubectl config current-context

# Get the kubeconfig file
export KUBECONFIG=$(k3d kubeconfig write ${cluster_name})

$kubectl get nodes
$kubectl get pods -n kube-system
