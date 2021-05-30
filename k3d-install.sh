#!/bin/bash
set -e
set -o pipefail
set -x

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | \
  TAG=v4.4.4 bash

k3d --version
helm version
# Client version
kubectl version

k3d cluster create dev \
   --port 8080:80@loadbalancer \
   --port 8443:443@loadbalancer \
   --servers 1 --agents 1 \
   --wait

docker ps

kubectl config current-context
#export KUBECONFIG=$(k3d kubeconfig write dev)

kubectl get nodes

kubectl create deployment nginx --image=nginx

kubectl create service clusterip nginx --tcp=80:80
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
