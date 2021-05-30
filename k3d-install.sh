#!/bin/bash
set -e
set -o pipefail
set -x

# get k3d
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | \
  TAG=v4.4.4 bash

# Get version
k3d --version
helm version
# Client version
kubectl version

# replace default lb with traefik v2
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
curl -O https://k3d.io/usage/guides/calico.yaml

# Create a cluster, mapping the ingress port 80 to localhost:8080 and 443 to 8443
#  1 server, 1 agent, traefik v2 and calico
k3d cluster create dev \
   --port 8080:80@loadbalancer \
   --port 8443:443@loadbalancer \
   --servers 1 --agents 1 \
   --k3s-server-arg '--no-deploy=traefik --flannel-backend=none' \
   --volume "$(pwd)/helm-ingress-traefik.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-traefik.yaml" \
   --volume "$(pwd)/calico.yaml:/var/lib/rancher/k3s/server/manifests/calico.yaml" \
   --wait

docker ps

kubectl config current-context

# Get the kubeconfig file
export KUBECONFIG=$(k3d kubeconfig write dev)

kubectl get nodes
kubectl get pods -n kube-system

# Create a nginx deployment
kubectl create deployment nginx --image=nginx

# Create a ClusterIP service 
kubectl create service clusterip nginx --tcp=80:80

# Create an ingress object for it
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF

# test up
set +e
timeout=120
test_result=1
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
        curl --fail -s -L http://localhost:8080/
        test_result=$?
        echo "Wait $timeout seconds: wait up $test_result";
        (( timeout-- ))
        sleep 1
done
set -e
if [ "$test_result" -gt "0" ] ; then
        ret=$test_result
        echo "ERROR"
        exit $ret
fi

# clean
k3d cluster delete dev
