SHELL = /bin/bash
APP ?= test
#
# k8s
#
#run-k3d-tests: k3d-install k3d-cluster-create k3d-load-images k3d-deploy k3d-cluster-delete
run-k3d-tests: k3d-install k3d-cluster-create k3d-deploy k3d-cluster-delete

k3d-load-images: build-dir k3d-load-image-proxy k3d-load-image-app k3d-load-image-api ## load images

k3d-load-image-%: $(BUILD_DIR)/$(FILE_IMAGE_$(call UC,$*)_APP_VERSION) ## load image
	if [ ! -d "images" ] ; then mkdir images  ; fi
	image_name=$$(${DC} -f $(DC_RUN_FILE) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin, Loader=yaml.SafeLoader), sys.stdout, indent=4)); print cfg["services"]["$*"]["image"]') ; \
	 docker tag $$image_name ${APP}-$*:${LATEST_VERSION} ; \
         docker image save ${APP}-$*:${LATEST_VERSION} -o images/$(FILE_IMAGE_$(call UC,$*)_LATEST_VERSION) && \
	k3d image import images/$(FILE_IMAGE_$(call UC,$*)_LATEST_VERSION) -c "${APP}-ci"

k3d-%:
	@if [ -x ci/k3d-$*.sh ] ; then  ci/k3d-$*.sh ; fi

# convert docker-compose format to k8s helm chart
get-kompose:
	[ -x kompose ] || curl -L https://github.com/kubernetes/kompose/releases/download/v1.22.0/kompose-${OS}-amd64 -o kompose
	chmod +x kompose

convert-docker-compose: kompose ${DC_RUN_FILE}
	./kompose -f ${DC_RUN_FILE} convert -o ${APP}-manifest.yml
