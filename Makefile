KIND_INSTANCE=k8s-ray-playground

RAY_OPERATOR_VERSION=0.6.0

# creates a K8s instance
.PHONY: k8s_new
k8s_new:
	kind create cluster --config ./kind/kind.yaml --name $(KIND_INSTANCE)

# deletes a k8s instance
.PHONY: k8s_drop
k8s_drop:
	kind delete cluster --name $(KIND_INSTANCE)

# sets KUBECONFIG for the K8s instance
.PHONY: k8s_connect
k8s_connect:
	kind export kubeconfig --name $(KIND_INSTANCE)

.PHONY: helm_init
helm_init:
	helm repo add kuberay https://ray-project.github.io/kuberay-helm/
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	
.PHONY: install_infra
install_infra: k8s_connect
	helm install kuberay-operator kuberay/kuberay-operator --version $(RAY_OPERATOR_VERSION)
	helm --namespace prometheus-system install prometheus prometheus-community/kube-prometheus-stack --create-namespace --version 48.2.1 -f ./k8s/prometheus/overrides.yaml

# install cluster with code embedded as a config map :-)
# to start a job port forward e.g. 
#    k port-forward svc/raycluster-embedded-code-head-svc 8265 
# then curl the head-node e.g.
#    curl -X POST http://127.0.0.1:8265/api/jobs/ \
#     -H 'Content-Type: application/json' \
#     -d '{"entrypoint": "python /opt/sample_code.py"}'
.PHONY: install_embedded_cluster_example
install_embedded_cluster_example:
	kubectl apply -f ./k8s/ray/cluster-embedded-code.yaml

# install cluster with a custom docker image
# NOTE: builds and sideloads the image (and it takes a long time)
# to start a job port forward e.g. 
#    k port-forward svc/raycluster-custom-image-head-svc 8265 
# then curl the head node e.g. 
#  curl -X POST http://127.0.0.1:8265/api/jobs/ \
#   -H 'Content-Type: application/json' \
#   -d '{"entrypoint": "python fib.py" }'
.PHONY: install_custom_image_example
install_custom_image_example: build_docker_image k8s_side_load 
	kubectl apply -f ./k8s/ray/cluster-custom-image.yaml

# loads the docker containers into the kind environments
.PHONY: k8s_side_load
k8s_side_load: k8s_connect
	kind load docker-image fib-app --name $(KIND_INSTANCE)

.PHONY: build_docker_image
build_docker_image:
	docker build -t fib-app:latest .
