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

.PHONY: install_infra
install_infra: k8s_connect
	helm install kuberay-operator kuberay/kuberay-operator --version $(RAY_OPERATOR_VERSION)
	helm install raycluster kuberay/ray-cluster --version $(RAY_OPERATOR_VERSION)

# loads the docker containers into the kind environments
.PHONY: k8s_side_load
k8s_side_load:
	kind load docker-image fib-app --name $(KIND_INSTANCE)

.PHONY: build_docker_image
build_docker_image:
	docker build -t fib-app:latest .
