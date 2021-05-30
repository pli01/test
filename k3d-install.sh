#!/bin/bash
set -e
set -o pipefail
set -x

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v4.4.4 bash

k3d cluster create dev \
   --port 8080:80@loadbalancer --port 8443:443@loadbalancer

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
        backend:
          serviceName: nginx
          servicePort: 80
EOF

curl --fail -s -L http://localhost:8080/
