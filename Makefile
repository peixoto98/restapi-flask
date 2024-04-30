APP = restapi-flask

test:
	@bandit -r . -x '*/.venv/*','*/tests/*'
	@black .
	@flake8 . --exclude .venv
	@pytest -v --disable-warnings

compose:
	@docker-compose build
	@docker-compose up

setup:
	@kind create cluster --config kubernetes/config.yaml

	# @kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
	# @kubectl wait --namespace metallb-system \
	# 		--for=condition=ready pod \
	# 		--selector=app=metallb \
	# 		--timeout=120s
	# @kubectl apply -f kubernetes/metallb-pool.yaml

	@helm repo add kong https://charts.konghq.com
	@helm install kong kong/kong -n ingress --create-namespace
	@kubectl wait --namespace ingress \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=270s

	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm install mongodb -n mongodb --create-namespace --set auth.rootPassword="root" bitnami/mongodb --version 12.1.31
	@kubectl wait --namespace mongodb
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=270s

	@kubectl cluster-info --context kind-kind

teardown:
	@kind delete clusters kind