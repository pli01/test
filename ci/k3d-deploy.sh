#!/bin/bash
set -x

cluster_name="${APP}-ci"

helm=$(type -p helm)
kubectl=$(type -p kubectl)


#
## deploy app
#

# helm format
#$helm install ${APP} k8s/helm --wait

# kubernetes manifest format
#$kubectl create -f k8s/manifest/${APP}-manifest.yaml

# Demo nginx only
$kubectl create deployment nginx --image=nginx
$kubectl create service clusterip nginx --tcp=80:80

# Create an ingress object for it
cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: proxy-ingress
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

$kubectl get pods
$kubectl get service
$kubectl get deployment
$kubectl get ingress

# test up
set +e
timeout=120
test_result=1

curl_args="--retry-max-time 120 --retry-delay 1  --retry 1"
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
        curl $curl_args -s --fail -L http://localhost:80/
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
