APP = restapi-flask

test:
	@bandit -r . -x '*/.venv/*','*/tests/*'
	@black .
	@flake8 . --exclude .venv
	@pytest -v --disable-warnings

compose:
	@docker-compose build
	@docker-compose up

setup-dev:
	@kind create cluster --config kubernetes/config.yaml

	# @kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
	# @kubectl wait --namespace metallb-system \
	# 		--for=condition=ready pod \
	# 		--selector=app=metallb \
	# 		--timeout=120s
	# @kubectl apply -f kubernetes/metallb-pool.yaml

	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@kubectl wait --namespace ingress-nginx \
	   --for=condition=ready pod \
	   --selector=app.kubernetes.io/component=controller \
	   --timeout=90s

	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm upgrade --install mongodb --set auth.rootPassword="root" bitnami/mongodb --version 12.1.31
	@kubectl wait \
	   --for=condition=ready pod \
	   --selector=app.kubernetes.io/component=mongodb \
	   --timeout=270s

	@kubectl cluster-info --context kind-kind

deploy-dev:
	@docker build -t $(APP):latest .
	@kind load docker-image $(APP):latest
	@kubectl apply -f kubernetes/manifests
	@kubectl rollout restart deploy restapi-flask

dev: setup-dev deploy-dev

teardown:
	@kind delete clusters kind